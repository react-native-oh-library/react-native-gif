import { abilityDelegatorRegistry, Component, Driver, ON } from '@kit.TestKit';
import { Want } from '@kit.AbilityKit';
import { describe, it, expect, beforeAll } from '@ohos/hypium';

const BUNDLE_NAME = 'com.example.application';
const ENTRY_ABILITY = 'EntryAbility';
// react-native-gif Example 首屏实际文案（Section 1 标题）
const PAGE_TITLE_TEXT = '1. 远程 GIF（onFrameChange / onLoadEnd）';
const POLL_INTERVAL_MS = 500;
const RN_LOAD_TIMEOUT_MS = 12000;
const RESULT_TIMEOUT_MS = 6000;

let appDriver: Driver | null = null;

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function startEntryAbility(): Promise<void> {
  const delegator = abilityDelegatorRegistry.getAbilityDelegator();
  const want: Want = {
    bundleName: BUNDLE_NAME,
    abilityName: ENTRY_ABILITY
  };
  await delegator.startAbility(want);
}

async function waitForText(
  driver: Driver,
  text: string,
  timeoutMs: number
): Promise<Component | null> {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    try {
      return await driver.findComponent(ON.text(text));
    } catch (_e) {
      await sleep(POLL_INTERVAL_MS);
    }
  }
  return null;
}

async function waitForId(
  driver: Driver,
  id: string,
  timeoutMs: number
): Promise<Component | null> {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    try {
      return await driver.findComponent(ON.id(id));
    } catch (_e) {
      await sleep(POLL_INTERVAL_MS);
    }
  }
  return null;
}

async function findMethodButton(
  driver: Driver,
  method: string,
  buttonText: string
): Promise<Component> {
  const byId = await waitForId(driver, `test-${method}-btn`, 2000);
  if (byId !== null) {
    return byId;
  }
  const byText = await waitForText(driver, buttonText, 2000);
  if (byText !== null) {
    return byText;
  }
  throw new Error(`Button not found for ${method}`);
}

export default function moduleTest(): void {
  describe('ExampleDeviceTest', () => {
    beforeAll(async () => {
      await startEntryAbility();
      appDriver = Driver.create();
      const title = await waitForText(appDriver, PAGE_TITLE_TEXT, RN_LOAD_TIMEOUT_MS);
      if (title === null) {
        const byId = await waitForId(appDriver, 'app-title', 3000);
        if (byId === null) {
          throw new Error('RN app did not load: title not found');
        }
      }
    });

    it('detectWhiteScreen', 0, async () => {
      expect(appDriver !== null).assertTrue();
      let hasContent = await waitForText(appDriver!, PAGE_TITLE_TEXT, 2000);
      if (hasContent === null) {
        hasContent = await waitForId(appDriver!, 'app-title', 2000);
      }
      expect(hasContent !== null).assertTrue();
    });

    it('resizeModeButtonsPresent', 0, async () => {
      const driver = appDriver!;
      // demo Section 2 的三个缩放模式按钮应全部存在
      for (const mode of ['contain', 'cover', 'stretch']) {
        const btn = await waitForText(driver, mode, 3000);
        expect(btn !== null).assertTrue();
      }
    });

    it('tapCoverSwitchesMode', 0, async () => {
      const driver = appDriver!;
      const coverBtn = await waitForText(driver, 'cover', 3000);
      expect(coverBtn !== null).assertTrue();
      await coverBtn!.click();
      await sleep(1000);
      // MODES[当前模式] InfoLine 应显示 cover 对应数值 2
      const modeLine = await waitForText(driver, 'MODES[当前模式]: 2', 4000);
      expect(modeLine !== null).assertTrue();
    });
  });
}
