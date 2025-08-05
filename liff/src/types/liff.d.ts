import '@line/liff';

declare global {
  interface Window {
    liff: typeof import('@line/liff').default;
  }
}