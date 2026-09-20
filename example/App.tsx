/**
 * Copyright (c) 2026 Huawei Technologies Co., Ltd.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 */
/**
 * react-native-gif HarmonyOS Example
 *
 * 覆盖核心 API：
 * - 远程 GIF 加载（onLoadEnd 成功 / onFrameChange 逐帧事件）
 * - resizeMode 三种模式切换（contain / cover / stretch，经 MODES 常量映射 contentMode）
 * - 静态图（非动图：onLoadEnd 正常触发、onFrameChange 不触发）
 * - 本地 require() 静态资源（asset:// 路径）
 * - 加载失败（无效 URL / 不存在的本地路径 → onLoadEnd({}) 空对象）
 */
import React, { useCallback, useState } from 'react';
import {
  SafeAreaView,
  ScrollView,
  View,
  Text,
  TouchableOpacity,
  StyleSheet,
  StatusBar,
} from 'react-native';
import FLAnimatedImage, { MODES } from 'react-native-gif';

type ResizeModeKey = 'contain' | 'cover' | 'stretch';

// 公开稳定的示例资源（OpenHarmony 官方文档仓库 gitee raw 直链，国内可达）：
// gitee raw 会 302 到 raw.giteeusercontent.com，鸿蒙 Network Kit http 默认跟随重定向。
// GIF 为 50 帧 / 225x207 / 每帧 60ms 的卡片翻转动画（肉眼持续变化）；
// onFrameChange 增速约 17 次/s 为正常（已实测确认 getDelayTimeList 返回毫秒）。
// 原 wikimedia 资源（境外，国内环境不可达）：
//   https://upload.wikimedia.org/wikipedia/commons/2/2c/Rotating_earth_%28large%29.gif
//   https://upload.wikimedia.org/wikipedia/commons/4/47/PNG_transparency_demonstration_1.png
const REMOTE_GIF_URL =
  'https://gitee.com/openharmony/docs/raw/master/en/application-dev/form/figures/WidgetAnimation.gif';
const REMOTE_STATIC_URL =
  'https://gitee.com/openharmony/docs/raw/master/zh-cn/application-dev/ui/figures/ButtonTypeValue.png';
// .invalid 是 RFC 保留的永不解析域名 → 网络加载必然失败
const INVALID_REMOTE_URL = 'https://gif.invalid/not-exist.gif';
// 沙箱内不存在的文件 → 本地路径加载必然失败
const INVALID_LOCAL_PATH = '/data/storage/el2/base/files/not-exist.gif';
const LOCAL_ASSET = require('./assets/loading.gif');

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <View style={styles.section}>
      <Text style={styles.sectionTitle}>{title}</Text>
      {children}
    </View>
  );
}

function InfoLine({ label, value }: { label: string; value: string }) {
  return (
    <Text style={styles.infoLine}>
      {label}: {value}
    </Text>
  );
}

export default function App() {
  const [resizeMode, setResizeMode] = useState<ResizeModeKey>('contain');

  // 远程 GIF：onLoadEnd 成功负载 + onFrameChange 逐帧统计
  const [remoteLoadEnd, setRemoteLoadEnd] = useState('未触发');
  const [frameEventCount, setFrameEventCount] = useState(0);
  const [lastFrameInfo, setLastFrameInfo] = useState('未触发');

  // 静态图
  const [staticLoadEnd, setStaticLoadEnd] = useState('未触发');

  // 本地资源（require → asset://）
  const [assetLoadEnd, setAssetLoadEnd] = useState('未触发');
  const [assetFrameEventCount, setAssetFrameEventCount] = useState(0);
  const [assetLastFrameInfo, setAssetLastFrameInfo] = useState('未触发');

  // 失败场景
  const [invalidRemoteLoadEnd, setInvalidRemoteLoadEnd] = useState('未触发');
  const [invalidLocalLoadEnd, setInvalidLocalLoadEnd] = useState('未触发');

  const onLoadEndToJson = useCallback((event: { nativeEvent: object }) => {
    const payload = event.nativeEvent;
    const keys = Object.keys(payload);
    if (keys.length === 0) {
      return '{}（空对象，加载失败）';
    }
    return JSON.stringify(payload);
  }, []);

  const onRemoteLoadEnd = useCallback(
    (event: any) => {
      setRemoteLoadEnd(onLoadEndToJson(event));
    },
    [onLoadEndToJson],
  );

  const onRemoteFrameChange = useCallback((event: any) => {
    const info = event.nativeEvent;
    setFrameEventCount((c) => c + 1);
    setLastFrameInfo(`第 ${info.currentFrameIndex} 帧 / 共 ${info.frameCount} 帧`);
  }, []);

  const onStaticLoadEnd = useCallback(
    (event: any) => {
      setStaticLoadEnd(onLoadEndToJson(event));
    },
    [onLoadEndToJson],
  );

  const onAssetLoadEnd = useCallback(
    (event: any) => {
      setAssetLoadEnd(onLoadEndToJson(event));
    },
    [onLoadEndToJson],
  );

  const onAssetFrameChange = useCallback((event: any) => {
    const info = event.nativeEvent;
    setAssetFrameEventCount((c) => c + 1);
    // 写专用 state，避免覆盖 Section 1 的远程帧信息显示
    setAssetLastFrameInfo(`第 ${info.currentFrameIndex} 帧 / 共 ${info.frameCount} 帧`);
  }, []);

  const onInvalidRemoteLoadEnd = useCallback(
    (event: any) => {
      setInvalidRemoteLoadEnd(onLoadEndToJson(event));
    },
    [onLoadEndToJson],
  );

  const onInvalidLocalLoadEnd = useCallback(
    (event: any) => {
      setInvalidLocalLoadEnd(onLoadEndToJson(event));
    },
    [onLoadEndToJson],
  );

  return (
    <SafeAreaView style={styles.root}>
      <StatusBar barStyle="dark-content" />
      <ScrollView contentContainerStyle={styles.scrollContent}>
        <Section title="1. 远程 GIF（onFrameChange / onLoadEnd）">
          <FLAnimatedImage
            source={{ uri: REMOTE_GIF_URL }}
            style={styles.remoteImage}
            resizeMode={resizeMode}
            onFrameChange={onRemoteFrameChange}
            onLoadEnd={onRemoteLoadEnd}
          />
          <InfoLine label="onLoadEnd" value={remoteLoadEnd} />
          <InfoLine label="onFrameChange 次数" value={String(frameEventCount)} />
          <InfoLine label="最近帧信息" value={lastFrameInfo} />
        </Section>

        <Section title="2. resizeMode 切换（contain=1 / cover=2 / stretch=0）">
          <View style={styles.row}>
            {(['contain', 'cover', 'stretch'] as ResizeModeKey[]).map((mode) => (
              <TouchableOpacity
                key={mode}
                style={[styles.modeButton, resizeMode === mode && styles.modeButtonActive]}
                onPress={() => setResizeMode(mode)}>
                <Text
                  style={[
                    styles.modeButtonText,
                    resizeMode === mode && styles.modeButtonTextActive,
                  ]}>
                  {mode}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
          <InfoLine label="MODES[当前模式]" value={String(MODES[resizeMode])} />
          <InfoLine
            label="提示"
            value="切换会以新 contentMode 重新加载上方远程 GIF（onLoadEnd 再次触发）"
          />
        </Section>

        <Section title="3. 静态图（PNG，无逐帧事件）">
          <FLAnimatedImage
            source={{ uri: REMOTE_STATIC_URL }}
            style={styles.staticImage}
            resizeMode="contain"
            onLoadEnd={onStaticLoadEnd}
          />
          <InfoLine label="onLoadEnd" value={staticLoadEnd} />
        </Section>

        <Section title="4. 本地静态资源（require → asset://）">
          <FLAnimatedImage
            source={LOCAL_ASSET}
            style={styles.localImage}
            resizeMode="contain"
            onFrameChange={onAssetFrameChange}
            onLoadEnd={onAssetLoadEnd}
          />
          <InfoLine label="onLoadEnd" value={assetLoadEnd} />
          <InfoLine label="onFrameChange 次数" value={String(assetFrameEventCount)} />
          <InfoLine label="最近帧信息" value={assetLastFrameInfo} />
        </Section>

        <Section title="5. 加载失败（无效 URL）">
          <FLAnimatedImage
            source={{ uri: INVALID_REMOTE_URL }}
            style={styles.failImage}
            resizeMode="contain"
            onLoadEnd={onInvalidRemoteLoadEnd}
          />
          <InfoLine label="onLoadEnd" value={invalidRemoteLoadEnd} />
        </Section>

        <Section title="6. 加载失败（本地路径不存在）">
          <FLAnimatedImage
            source={{ uri: INVALID_LOCAL_PATH }}
            style={styles.failImage}
            resizeMode="contain"
            onLoadEnd={onInvalidLocalLoadEnd}
          />
          <InfoLine label="onLoadEnd" value={invalidLocalLoadEnd} />
        </Section>
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: '#F3F3F3',
  },
  scrollContent: {
    paddingBottom: 40,
  },
  section: {
    marginTop: 16,
    marginHorizontal: 16,
    padding: 12,
    backgroundColor: '#FFFFFF',
    borderRadius: 8,
  },
  sectionTitle: {
    fontSize: 15,
    fontWeight: 'bold',
    color: '#222222',
    marginBottom: 8,
  },
  remoteImage: {
    width: '100%',
    height: 160,
    backgroundColor: '#EAEAEA',
  },
  staticImage: {
    width: '100%',
    height: 120,
    backgroundColor: '#EAEAEA',
  },
  localImage: {
    width: '100%',
    height: 80,
    backgroundColor: '#EAEAEA',
  },
  failImage: {
    width: '100%',
    height: 60,
    backgroundColor: '#EAEAEA',
  },
  row: {
    flexDirection: 'row',
    marginBottom: 8,
  },
  modeButton: {
    flex: 1,
    paddingVertical: 8,
    marginRight: 8,
    borderRadius: 6,
    backgroundColor: '#EEF1F6',
    alignItems: 'center',
  },
  modeButtonActive: {
    backgroundColor: '#287DFA',
  },
  modeButtonText: {
    fontSize: 14,
    color: '#222222',
  },
  modeButtonTextActive: {
    color: '#FFFFFF',
  },
  infoLine: {
    fontSize: 12,
    color: '#555555',
    marginTop: 4,
  },
});
