// Consent Mode のパラメータ型
export type ConsentParams = {
  analytics_storage?: 'granted' | 'denied';
  ad_storage?: 'granted' | 'denied';
  ad_user_data?: 'granted' | 'denied';
  ad_personalization?: 'granted' | 'denied';
  wait_for_update?: number;
};

// Gtag Config パラメータ型
export type GtagConfigParams = {
  page_path?: string;
  page_title?: string;
  send_page_view?: boolean;
  [key: string]: string | number | boolean | undefined;
};

// Gtag Event パラメータ型
export type GtagEventParams = {
  event_category?: string;
  event_label?: string;
  value?: number;
  [key: string]: string | number | boolean | undefined;
};

// Gtag関数のオーバーロード定義（anyを使用しない）
export type GtagFunction = {
  (command: 'consent', action: 'default' | 'update', params: ConsentParams): void;
  (command: 'config', targetId: string, config?: GtagConfigParams): void;
  (command: 'event', eventName: string, params?: GtagEventParams): void;
  (command: 'set', params: Record<string, string | number | boolean>): void;
  (command: 'get', targetId: string, fieldName: string, callback: (value: string) => void): void;
};

// Window拡張
declare global {
  interface Window {
    dataLayer: Array<unknown>;
    gtag?: GtagFunction;
  }
}
