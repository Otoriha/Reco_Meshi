import React from 'react';
import { Link } from 'react-router-dom';

const Privacy: React.FC = () => {
  return (
    <div className="min-h-screen bg-gray-50 py-12">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="bg-white shadow-sm rounded-lg p-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">プライバシーポリシー</h1>
          <p className="text-sm text-gray-600 mb-8">最終更新日: 2025年10月1日</p>

          <div className="prose prose-green max-w-none">
            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 mb-4">1. はじめに</h2>
              <p className="text-gray-700 leading-relaxed mb-4">
                レコめし（以下「当サービス」といいます）は、ユーザーの皆様の個人情報保護の重要性について認識し、個人情報の保護に関する法律（以下「個人情報保護法」といいます）を遵守すると共に、以下のプライバシーポリシー（以下「本ポリシー」といいます）に従い、適切な取扱い及び保護に努めます。
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 mb-4">2. 個人情報の定義</h2>
              <p className="text-gray-700 leading-relaxed">
                本ポリシーにおいて、個人情報とは、個人情報保護法第2条第1項により定義された個人情報、すなわち、生存する個人に関する情報であって、当該情報に含まれる氏名、生年月日その他の記述等により特定の個人を識別することができるもの（他の情報と容易に照合することができ、それにより特定の個人を識別することができることとなるものを含みます）を指します。
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 mb-4">3. 収集する情報</h2>
              <p className="text-gray-700 leading-relaxed mb-2">
                当サービスでは、以下の情報を収集する場合があります。
              </p>
              <ul className="list-disc list-inside text-gray-700 space-y-2 ml-4">
                <li>氏名、メールアドレス等、ユーザーが登録した情報</li>
                <li>LINE連携時のLINE ID、プロフィール情報</li>
                <li>ユーザーが投稿した食材情報、画像データ</li>
                <li>レシピの閲覧履歴、お気に入り情報</li>
                <li>デバイス情報、IPアドレス、Cookie情報</li>
                <li>サービス利用状況に関する情報</li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 mb-4">4. 情報の利用目的</h2>
              <p className="text-gray-700 leading-relaxed mb-2">
                当サービスは、収集した個人情報を以下の目的で利用します。
              </p>
              <ul className="list-disc list-inside text-gray-700 space-y-2 ml-4">
                <li>当サービスの提供、維持、改善のため</li>
                <li>ユーザーの認証およびアカウント管理のため</li>
                <li>食材管理機能の提供およびレシピ提案のため</li>
                <li>ユーザーからのお問い合わせへの対応のため</li>
                <li>利用規約違反行為への対応のため</li>
                <li>サービスの改善、新機能の開発のため</li>
                <li>統計データの作成および分析のため</li>
                <li>重要なお知らせなど必要に応じた連絡のため</li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 mb-4">5. 情報の第三者提供</h2>
              <p className="text-gray-700 leading-relaxed mb-4">
                当サービスは、以下の場合を除き、ユーザーの個人情報を第三者に提供することはありません。
              </p>
              <ul className="list-disc list-inside text-gray-700 space-y-2 ml-4">
                <li>ユーザーの同意がある場合</li>
                <li>法令に基づく場合</li>
                <li>人の生命、身体または財産の保護のために必要がある場合であって、本人の同意を得ることが困難である場合</li>
                <li>国の機関もしくは地方公共団体またはその委託を受けた者が法令の定める事務を遂行することに対して協力する必要がある場合</li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 mb-4">6. 外部サービスの利用</h2>
              <p className="text-gray-700 leading-relaxed mb-2">
                当サービスは、以下の外部サービスを利用しており、それぞれのプライバシーポリシーに従って情報が処理されます。
              </p>
              <ul className="list-disc list-inside text-gray-700 space-y-2 ml-4">
                <li>LINE（ユーザー認証、メッセージ送信）</li>
                <li>Google Cloud Vision API（画像認識）</li>
                <li>OpenAI APIまたはGoogle Gemini API（レシピ生成）</li>
              </ul>
              <p className="text-gray-700 leading-relaxed mt-4">
                これらのサービスを利用する際、必要最小限の情報のみが送信されます。
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 mb-4">7. Cookieおよび類似技術</h2>
              <p className="text-gray-700 leading-relaxed mb-4">
                当サービスは、ユーザー体験の向上、サービスの利用状況の分析のため、Cookieおよび類似技術を使用します。
              </p>
              <p className="text-gray-700 leading-relaxed">
                ユーザーは、ブラウザの設定によりCookieの受け入れを拒否することができますが、その場合、当サービスの一部機能が利用できなくなる可能性があります。
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 mb-4">8. 個人情報の管理</h2>
              <p className="text-gray-700 leading-relaxed mb-4">
                当サービスは、ユーザーの個人情報を正確かつ最新の状態に保つよう努め、不正アクセス、紛失、破壊、改ざん、漏洩などを防止するため、適切なセキュリティ対策を実施します。
              </p>
              <p className="text-gray-700 leading-relaxed">
                個人情報は、利用目的の達成に必要な期間に限り保持し、不要となった場合は速やかに削除または匿名化します。
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 mb-4">9. ユーザーの権利</h2>
              <p className="text-gray-700 leading-relaxed mb-2">
                ユーザーは、自己の個人情報について、以下の権利を有します。
              </p>
              <ul className="list-disc list-inside text-gray-700 space-y-2 ml-4">
                <li>開示を求める権利</li>
                <li>訂正、追加または削除を求める権利</li>
                <li>利用の停止または消去を求める権利</li>
                <li>第三者提供の停止を求める権利</li>
              </ul>
              <p className="text-gray-700 leading-relaxed mt-4">
                これらの権利を行使される場合は、当サービスのお問い合わせフォームよりご連絡ください。
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 mb-4">10. 未成年者の個人情報</h2>
              <p className="text-gray-700 leading-relaxed">
                当サービスは、原則として18歳未満の方の個人情報を収集しません。18歳未満の方が当サービスを利用する場合は、保護者の同意を得た上でご利用ください。
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 mb-4">11. プライバシーポリシーの変更</h2>
              <p className="text-gray-700 leading-relaxed mb-4">
                当サービスは、法令の変更、サービス内容の変更等に伴い、本ポリシーを変更することがあります。
              </p>
              <p className="text-gray-700 leading-relaxed">
                変更後のプライバシーポリシーは、当サービス上に掲載した時点から効力を生じるものとします。重要な変更がある場合は、当サービス内で通知いたします。
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 mb-4">12. お問い合わせ</h2>
              <p className="text-gray-700 leading-relaxed">
                本ポリシーに関するお問い合わせは、当サービスのお問い合わせフォームよりご連絡ください。
              </p>
            </section>
          </div>

          <div className="mt-12 pt-8 border-t border-gray-200">
            <Link
              to="/"
              className="inline-block bg-green-600 text-white px-6 py-3 rounded-md hover:bg-green-700 transition-colors font-medium"
            >
              ホームに戻る
            </Link>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Privacy;
