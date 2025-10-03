import React from 'react';
import { Link } from 'react-router-dom';

const Terms: React.FC = () => {
  return (
    <div className="min-h-screen bg-gray-50 py-12">
      <div className="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="bg-white shadow-sm rounded-lg p-8">
          <h1 className="text-3xl font-bold text-gray-900 mb-2">利用規約</h1>
          <p className="text-sm text-gray-600 mb-8">最終更新日: 2025年10月1日</p>

          <div className="prose prose-green max-w-none">
            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 mb-4">第1条（適用）</h2>
              <p className="text-gray-700 leading-relaxed mb-4">
                本規約は、レコめし（以下「当サービス」といいます）の利用に関する条件を、当サービスを利用するすべてのユーザー（以下「ユーザー」といいます）と当サービス運営者（以下「運営者」といいます）との間で定めるものです。
              </p>
              <p className="text-gray-700 leading-relaxed">
                ユーザーは、当サービスを利用することにより、本規約の全ての内容に同意したものとみなされます。
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 mb-4">第2条（定義）</h2>
              <p className="text-gray-700 leading-relaxed mb-2">
                本規約において使用する用語の定義は、以下のとおりとします。
              </p>
              <ul className="list-disc list-inside text-gray-700 space-y-2 ml-4">
                <li>「当サービス」とは、運営者が提供する「レコめし」という名称の食材管理およびレシピ提案サービスを指します。</li>
                <li>「ユーザー」とは、当サービスを利用するすべての個人を指します。</li>
                <li>「登録情報」とは、ユーザーが当サービスに登録した情報を指します。</li>
                <li>「コンテンツ」とは、ユーザーが当サービスを通じて投稿、送信、アップロードした情報を指します。</li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 mb-4">第3条（アカウント登録）</h2>
              <p className="text-gray-700 leading-relaxed mb-4">
                ユーザーは、当サービスの利用にあたり、正確かつ最新の情報を提供して登録を行うものとします。
              </p>
              <p className="text-gray-700 leading-relaxed mb-4">
                ユーザーは、登録情報に変更が生じた場合、速やかに当該情報を更新するものとします。
              </p>
              <p className="text-gray-700 leading-relaxed">
                ユーザーは、自己の責任において、アカウント情報および認証情報を適切に管理するものとします。
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 mb-4">第4条（禁止事項）</h2>
              <p className="text-gray-700 leading-relaxed mb-2">
                ユーザーは、当サービスの利用にあたり、以下の行為を行ってはなりません。
              </p>
              <ul className="list-disc list-inside text-gray-700 space-y-2 ml-4">
                <li>法令または公序良俗に違反する行為</li>
                <li>犯罪行為に関連する行為</li>
                <li>運営者または第三者の知的財産権、肖像権、プライバシー、名誉その他の権利または利益を侵害する行為</li>
                <li>当サービスのネットワークまたはシステム等に過度な負荷をかける行為</li>
                <li>当サービスの運営を妨害するおそれのある行為</li>
                <li>不正アクセスをし、またはこれを試みる行為</li>
                <li>他のユーザーに関する個人情報等を収集または蓄積する行為</li>
                <li>他のユーザーに成りすます行為</li>
                <li>反社会的勢力に対して直接または間接に利益を供与する行為</li>
                <li>その他、運営者が不適切と判断する行為</li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 mb-4">第5条（当サービスの提供の停止等）</h2>
              <p className="text-gray-700 leading-relaxed mb-2">
                運営者は、以下のいずれかの事由があると判断した場合、ユーザーに事前に通知することなく当サービスの全部または一部の提供を停止または中断することができるものとします。
              </p>
              <ul className="list-disc list-inside text-gray-700 space-y-2 ml-4">
                <li>当サービスにかかるコンピュータシステムの保守点検または更新を行う場合</li>
                <li>地震、落雷、火災、停電または天災などの不可抗力により、当サービスの提供が困難となった場合</li>
                <li>コンピュータまたは通信回線等が事故により停止した場合</li>
                <li>その他、運営者が当サービスの提供が困難と判断した場合</li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 mb-4">第6条（利用制限および登録抹消）</h2>
              <p className="text-gray-700 leading-relaxed mb-2">
                運営者は、以下の場合には、事前の通知なく、ユーザーに対して、当サービスの全部もしくは一部の利用を制限し、またはユーザーとしての登録を抹消することができるものとします。
              </p>
              <ul className="list-disc list-inside text-gray-700 space-y-2 ml-4">
                <li>本規約のいずれかの条項に違反した場合</li>
                <li>登録事項に虚偽の事実があることが判明した場合</li>
                <li>その他、運営者が当サービスの利用を適当でないと判断した場合</li>
              </ul>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 mb-4">第7条（免責事項）</h2>
              <p className="text-gray-700 leading-relaxed mb-4">
                運営者は、当サービスに関して、ユーザーと他のユーザーまたは第三者との間において生じた取引、連絡または紛争等について一切責任を負いません。
              </p>
              <p className="text-gray-700 leading-relaxed mb-4">
                当サービスは、食材の管理およびレシピの提案を支援するものであり、提供される情報の正確性、完全性、有用性等について保証するものではありません。
              </p>
              <p className="text-gray-700 leading-relaxed">
                ユーザーは、当サービスを利用することにより生じた損害について、運営者が一切の責任を負わないことに同意するものとします。
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 mb-4">第8条（サービス内容の変更等）</h2>
              <p className="text-gray-700 leading-relaxed">
                運営者は、ユーザーに通知することなく、当サービスの内容を変更し、または当サービスの提供を中止することができるものとし、これによってユーザーに生じた損害について一切の責任を負いません。
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 mb-4">第9条（利用規約の変更）</h2>
              <p className="text-gray-700 leading-relaxed mb-4">
                運営者は、必要と判断した場合には、ユーザーに通知することなくいつでも本規約を変更することができるものとします。
              </p>
              <p className="text-gray-700 leading-relaxed">
                変更後の本規約は、当サービス上に表示した時点より効力を生じるものとします。
              </p>
            </section>

            <section className="mb-8">
              <h2 className="text-2xl font-semibold text-gray-900 mb-4">第10条（準拠法・裁判管轄）</h2>
              <p className="text-gray-700 leading-relaxed mb-4">
                本規約の解釈にあたっては、日本法を準拠法とします。
              </p>
              <p className="text-gray-700 leading-relaxed">
                当サービスに関して紛争が生じた場合には、運営者の所在地を管轄する裁判所を専属的合意管轄とします。
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

export default Terms;
