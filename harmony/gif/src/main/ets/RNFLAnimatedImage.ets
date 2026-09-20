/**
 * Copyright (c) 2026 Huawei Technologies Co., Ltd.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
/**
 * RNFLAnimatedImage —— react-native-gif 鸿蒙侧 Fabric 组件实现。
 *
 * 对齐 iOS 版行为（RNFLAnimatedImage.m）：
 * - src 支持 http/https 远程地址：先拉取网络字节流（Network Kit http），
 *   失败则回退按本地路径解析（对齐 dataWithContentsOfURL → dataWithContentsOfFile 双路径语义）；
 * - 额外支持 RNOH 本地静态资源（asset://，即 require() 经 resolveAssetSource 的产物），
 *   对齐原库 source={require(...)} 用法；
 * - 加载成功触发 onLoadEnd({size:{width,height}})，失败触发 onLoadEnd({})（空对象）；
 * - contentMode 数值语义对齐 iOS UIViewContentMode（0=拉伸 1=等比适应 2=等比填满），
 *   映射 ArkUI objectFit(ImageFit)；
 * - 逐帧事件 onFrameChange({currentFrameIndex, frameCount})：用 Image Kit ImageSource
 *   的 getFrameCount()/getDelayTimeList() 驱动与动图播放节奏一致的定时上报。
 */

import { RNOHContext, RNViewBase } from '@rnoh/react-native-openharmony';
import { RNC } from './generated';
import { image } from '@kit.ImageKit';
import { http } from '@kit.NetworkKit';
import { fileIo, fileUri } from '@kit.CoreFileKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const CONTENT_MODE_SCALE_TO_FILL: number = 0;
const CONTENT_MODE_SCALE_ASPECT_FIT: number = 1;
const CONTENT_MODE_SCALE_ASPECT_FILL: number = 2;
const DEFAULT_FRAME_DELAY_MS: number = 100;
const HTTP_TIMEOUT_MS: number = 15000;
const HTTP_STATUS_OK_MIN: number = 200;
const HTTP_STATUS_OK_MAX_EXCLUSIVE: number = 300;
const LOG_DOMAIN: number = 0x0000;
const LOG_TAG: string = 'RNFLAnimatedImage';

function u8ToBuffer(content: Uint8Array): ArrayBuffer {
  // getRawFileContent 返回独占分配的 Uint8Array：视图对齐时直接复用底层 buffer（零拷贝），
  // 否则用 buffer.slice 走原生 memcpy，避免 JS 层逐字节循环拷贝（MB 级 GIF 的性能税）。
  if (content.byteOffset === 0 && content.length === content.buffer.byteLength) {
    return content.buffer;
  }
  return content.buffer.slice(content.byteOffset, content.byteOffset + content.length);
}

@Component
export struct RNFLAnimatedImage {
  public static readonly NAME = RNC.RNFLAnimatedImage.NAME;
  public ctx!: RNOHContext;
  public tag: number = 0;

  @State displayUri: string = '';
  @State rawfilePath: string = '';
  @State fit: ImageFit = ImageFit.Contain;

  private eventEmitter: RNC.RNFLAnimatedImage.EventEmitter | undefined = undefined;
  private cleanUpCallbacks: (() => void)[] = [];
  private imageSource: image.ImageSource | undefined = undefined;
  private frameTimerId: number = -1;
  private currentFrameIndex: number = 0;
  private frameCount: number = 0;
  private delayTimes: number[] = [];
  private loadToken: number = 0;
  private lastSrc: string | undefined = undefined;
  private lastContentMode: number | undefined = undefined;
  private tempFilePath: string | undefined = undefined;
  private lastFetchedUrl: string | undefined = undefined;

  aboutToAppear(): void {
    this.eventEmitter = new RNC.RNFLAnimatedImage.EventEmitter(this.ctx.rnInstance, this.tag);
    const wrapper =
      this.ctx.descriptorRegistry.findDescriptorWrapperByTag<RNC.RNFLAnimatedImage.DescriptorWrapper>(this.tag);
    if (wrapper !== null && wrapper !== undefined) {
      this.onDescriptorChange(wrapper);
    }
    this.cleanUpCallbacks.push(
      this.ctx.descriptorRegistry.subscribeToDescriptorChanges(this.tag, (descriptor) => {
        this.onDescriptorChange(new RNC.RNFLAnimatedImage.DescriptorWrapper(descriptor));
      })
    );
  }

  aboutToDisappear(): void {
    this.loadToken += 1;
    this.stopFrameTimer();
    this.releaseImageSource();
    this.cleanUpCallbacks.forEach((cb: () => void) => cb());
    if (this.tempFilePath !== undefined) {
      try {
        fileIo.unlinkSync(this.tempFilePath);
      } catch (e) {
        // 临时文件可能已被系统清理，忽略
        hilog.debug(LOG_DOMAIN, LOG_TAG, 'unlink temp file failed: %{public}s', `${e}`);
      }
      this.tempFilePath = undefined;
    }
  }

  private onDescriptorChange(wrapper: RNC.RNFLAnimatedImage.DescriptorWrapper): void {
    const src = wrapper.props.src;
    const contentMode = wrapper.props.contentMode;
    // 对齐 iOS：src 或 contentMode 变化才 reload（首次挂载 contentMode 必然从 undefined 变为数值，触发一次加载）
    if (src === this.lastSrc && contentMode === this.lastContentMode) {
      return;
    }
    this.lastSrc = src;
    this.lastContentMode = contentMode;
    this.startLoad(src, contentMode);
  }

  private startLoad(src: string | undefined, contentMode: number): void {
    this.loadToken += 1;
    const token = this.loadToken;
    this.updateFit(contentMode);
    this.stopFrameTimer();
    this.rawfilePath = '';
    if (src === undefined || src.length === 0) {
      this.emitLoadEnd(undefined);
      return;
    }
    if (this.isRemote(src)) {
      this.loadRemote(src, token);
      return;
    }
    if (src.startsWith('asset://')) {
      this.loadAsset(src, token);
      return;
    }
    this.loadLocal(this.normalizeLocalPath(src), token);
  }

  private isRemote(src: string): boolean {
    return src.startsWith('https://') || src.startsWith('http://');
  }

  private normalizeLocalPath(src: string): string {
    let path = src;
    if (path.startsWith('file://')) {
      path = path.substring('file://'.length);
    }
    try {
      path = decodeURIComponent(path);
    } catch (e) {
      // 非法编码序列时保留原样
      hilog.debug(LOG_DOMAIN, LOG_TAG, 'decodeURIComponent failed, keep raw path: %{public}s', `${e}`);
    }
    return path;
  }

  private updateFit(contentMode: number): void {
    if (contentMode === CONTENT_MODE_SCALE_TO_FILL) {
      this.fit = ImageFit.Fill;
    } else if (contentMode === CONTENT_MODE_SCALE_ASPECT_FILL) {
      this.fit = ImageFit.Cover;
    } else {
      this.fit = ImageFit.Contain;
    }
  }

  private async loadRemote(url: string, token: number): Promise<void> {
    // 同 URL 已缓存到本地临时文件 → 复用（contentMode 变更触发的 reload 不重复拉网）
    if (this.tempFilePath !== undefined && this.lastFetchedUrl === url) {
      this.finishLoad(this.tempFilePath, undefined, token);
      return;
    }
    const httpRequest = http.createHttp();
    try {
      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.GET,
        expectDataType: http.HttpDataType.ARRAY_BUFFER,
        connectTimeout: HTTP_TIMEOUT_MS,
        readTimeout: HTTP_TIMEOUT_MS,
      };
      const response: http.HttpResponse = await httpRequest.request(url, options);
      httpRequest.destroy();
      if (token !== this.loadToken) {
        return;
      }
      const data = response.result;
      if (response.responseCode < HTTP_STATUS_OK_MIN || response.responseCode >= HTTP_STATUS_OK_MAX_EXCLUSIVE ||
        typeof data === 'string' || !(data instanceof ArrayBuffer)) {
        // 拉流失败 → 回退本地路径语义（对齐 iOS）
        this.loadLocal(this.normalizeLocalPath(url), token);
        return;
      }
      const buffer = data as ArrayBuffer;
      const path = this.writeTempFile(buffer, url);
      if (path.length === 0) {
        this.loadLocal(this.normalizeLocalPath(url), token);
        return;
      }
      this.lastFetchedUrl = url;
      this.finishLoad(path, buffer, token);
    } catch (e) {
      httpRequest.destroy();
      if (token !== this.loadToken) {
        return;
      }
      // 网络异常 → 回退本地路径语义（对齐 iOS）
      hilog.warn(LOG_DOMAIN, LOG_TAG, 'fetch remote gif failed, fall back to local, url=%{public}s: %{public}s',
        url, `${e}`);
      this.loadLocal(this.normalizeLocalPath(url), token);
    }
  }

  private async loadAsset(uri: string, token: number): Promise<void> {
    try {
      const rel = uri.replace('asset://', this.ctx.rnInstance.getAssetsDest());
      const content: Uint8Array = await this.ctx.uiAbilityContext.resourceManager.getRawFileContent(rel);
      if (token !== this.loadToken) {
        return;
      }
      const imgSource = image.createImageSource(u8ToBuffer(content));
      if (imgSource === undefined || imgSource === null) {
        this.emitLoadEnd(undefined);
        return;
      }
      this.releaseImageSource();
      this.imageSource = imgSource;
      const info: image.ImageInfo = await imgSource.getImageInfo();
      if (token !== this.loadToken) {
        return;
      }
      this.displayUri = '';
      this.rawfilePath = rel;
      this.emitLoadEnd(info.size);
      await this.startFrameTracking(imgSource, token);
    } catch (e) {
      if (token !== this.loadToken) {
        return;
      }
      hilog.warn(LOG_DOMAIN, LOG_TAG, 'load asset gif failed, uri=%{public}s: %{public}s', uri, `${e}`);
      this.emitLoadEnd(undefined);
    }
  }

  private loadLocal(path: string, token: number): void {
    if (path.length === 0) {
      this.emitLoadEnd(undefined);
      return;
    }
    let exists = false;
    try {
      exists = fileIo.accessSync(path);
    } catch (e) {
      hilog.debug(LOG_DOMAIN, LOG_TAG, 'access path failed, treat as not exists, path=%{public}s: %{public}s',
        path, `${e}`);
      exists = false;
    }
    if (!exists) {
      this.emitLoadEnd(undefined);
      return;
    }
    this.finishLoad(path, undefined, token);
  }

  private async finishLoad(path: string, buffer: ArrayBuffer | undefined, token: number): Promise<void> {
    let imgSource: image.ImageSource | undefined = undefined;
    try {
      if (buffer !== undefined) {
        imgSource = image.createImageSource(buffer);
      } else {
        imgSource = image.createImageSource(path);
      }
    } catch (e) {
      // 与 loadAsset 对称：createImageSource 同步抛出（参数非法）时兜底，保证 fire-and-forget 调用点全路径安全
      hilog.warn(LOG_DOMAIN, LOG_TAG, 'createImageSource threw, path=%{public}s: %{public}s', path, `${e}`);
      this.emitLoadEnd(undefined);
      return;
    }
    if (imgSource === undefined || imgSource === null) {
      this.emitLoadEnd(undefined);
      return;
    }
    this.releaseImageSource();
    this.imageSource = imgSource;
    try {
      const info: image.ImageInfo = await imgSource.getImageInfo();
      if (token !== this.loadToken) {
        return;
      }
      this.displayUri = fileUri.getUriFromPath(path);
      this.emitLoadEnd(info.size);
      await this.startFrameTracking(imgSource, token);
    } catch (e) {
      if (token !== this.loadToken) {
        return;
      }
      hilog.warn(LOG_DOMAIN, LOG_TAG, 'getImageInfo failed, path=%{public}s: %{public}s', path, `${e}`);
      this.releaseImageSource();
      this.emitLoadEnd(undefined);
    }
  }

  private async startFrameTracking(imgSource: image.ImageSource, token: number): Promise<void> {
    let frameCount = 1;
    try {
      frameCount = await imgSource.getFrameCount();
    } catch (e) {
      frameCount = 1;
    }
    if (token !== this.loadToken || frameCount <= 1) {
      return;
    }
    let delays: number[] = [];
    try {
      delays = await imgSource.getDelayTimeList();
    } catch (e) {
      delays = [];
    }
    if (token !== this.loadToken || delays.length === 0) {
      return;
    }
    this.frameCount = frameCount;
    this.delayTimes = [];
    for (let i = 0; i < delays.length; i++) {
      // GIF 规范：延迟 0 视为 100ms
      const delay = delays[i] > 0 ? delays[i] : DEFAULT_FRAME_DELAY_MS;
      this.delayTimes.push(delay);
    }
    this.currentFrameIndex = 0;
    this.scheduleNextFrame();
  }

  private scheduleNextFrame(): void {
    if (this.frameCount <= 1 || this.delayTimes.length === 0) {
      return;
    }
    const delayIndex = this.currentFrameIndex % this.delayTimes.length;
    const delay = this.delayTimes[delayIndex];
    this.frameTimerId = setTimeout(() => {
      if (this.frameTimerId < 0) {
        return;
      }
      this.currentFrameIndex = (this.currentFrameIndex + 1) % this.frameCount;
      if (this.eventEmitter !== undefined) {
        this.eventEmitter.emit('frameChange', {
          currentFrameIndex: this.currentFrameIndex,
          frameCount: this.frameCount,
        });
      }
      this.scheduleNextFrame();
    }, delay);
  }

  private stopFrameTimer(): void {
    if (this.frameTimerId >= 0) {
      clearTimeout(this.frameTimerId);
      this.frameTimerId = -1;
    }
    this.frameCount = 0;
    this.currentFrameIndex = 0;
    this.delayTimes = [];
  }

  private releaseImageSource(): void {
    if (this.imageSource !== undefined) {
      this.imageSource.release().catch(() => {
      });
      this.imageSource = undefined;
    }
  }

  private writeTempFile(buffer: ArrayBuffer, url: string): string {
    const ext = this.extractExtFromUrl(url);
    const path = `${this.ctx.uiAbilityContext.cacheDir}/rnfl_animated_image_${this.tag}${ext}`;
    try {
      if (this.tempFilePath !== undefined && this.tempFilePath !== path) {
        fileIo.unlinkSync(this.tempFilePath);
      }
      const file: fileIo.File = fileIo.openSync(
        path,
        fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC
      );
      fileIo.writeSync(file.fd, buffer);
      fileIo.closeSync(file);
      this.tempFilePath = path;
      return path;
    } catch (e) {
      hilog.warn(LOG_DOMAIN, LOG_TAG, 'write temp gif file failed, path=%{public}s: %{public}s', path, `${e}`);
      return '';
    }
  }

  private extractExtFromUrl(url: string): string {
    const queryIdx = url.indexOf('?');
    const pathPart = queryIdx >= 0 ? url.substring(0, queryIdx) : url;
    const dotIdx = pathPart.lastIndexOf('.');
    const slashIdx = pathPart.lastIndexOf('/');
    if (dotIdx > slashIdx && dotIdx >= 0) {
      const ext = pathPart.substring(dotIdx).toLowerCase();
      if (ext.length >= 2 && ext.length <= 6) {
        return ext;
      }
    }
    return '.gif';
  }

  private emitLoadEnd(size: image.Size | undefined): void {
    if (this.eventEmitter === undefined) {
      return;
    }
    if (size !== undefined) {
      this.eventEmitter.emit('loadEnd', { size: { width: size.width, height: size.height } });
    } else {
      this.eventEmitter.emit('loadEnd', {});
    }
  }

  build() {
    RNViewBase({ ctx: this.ctx, tag: this.tag }) {
      if (this.rawfilePath.length > 0) {
        Image($rawfile(this.rawfilePath))
          .objectFit(this.fit)
          .width('100%')
          .height('100%')
      } else {
        Image(this.displayUri)
          .objectFit(this.fit)
          .width('100%')
          .height('100%')
      }
    }
  }
}
