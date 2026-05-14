import React from 'react';

const DataDeletion = () => {
  return (
    <div className="min-h-screen bg-gray-50 py-12 px-4 sm:px-6 lg:px-8">
      <div className="max-w-3xl mx-auto bg-white shadow-xl rounded-2xl overflow-hidden">
        <div className="px-8 py-10">
          <h1 className="text-4xl font-extrabold text-gray-900 mb-8 border-b pb-4">Data Deletion Request</h1>
          <div className="prose prose-blue max-w-none text-gray-600 space-y-6">
            <p className="text-sm text-gray-400 italic">Last Updated: May 15, 2026</p>

            <section>
              <p>
                At <strong>Will</strong>, developed by <strong>Lavish</strong>, we value your privacy and give you full control over your data.
                You can request the deletion of your account and all associated data at any time.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-bold text-gray-800 mb-4">How to Request Data Deletion</h2>
              <div className="space-y-4">
                <div>
                  <h3 className="text-xl font-semibold text-gray-800 mb-2">Method 1: In-App Deletion (Recommended)</h3>
                  <ol className="list-decimal pl-6 space-y-2">
                    <li>Open the <strong>Will</strong> app on your device.</li>
                    <li>Log in to your account.</li>
                    <li>Go to the <strong>Profile</strong> screen.</li>
                    <li>Scroll to the bottom and tap on <strong>Delete Account</strong>.</li>
                    <li>Confirm the deletion. Your account and all associated data will be removed instantly from our production servers.</li>
                  </ol>
                </div>
                
                <div>
                  <h3 className="text-xl font-semibold text-gray-800 mb-2">Method 2: Email Request</h3>
                  <p>
                    If you are unable to access the app, you can send an email to our support team at:
                    <br />
                    <strong className="text-blue-600">templavish9@gmail.com</strong>
                  </p>
                  <p className="mt-2 text-sm">Please include "Data Deletion Request" in the subject line and provide the email address associated with your account.</p>
                </div>
              </div>
            </section>

            <section>
              <h2 className="text-2xl font-bold text-gray-800 mb-4">What Data is Deleted?</h2>
              <p>Upon a successful deletion request, the following data is permanently removed from our active databases:</p>
              <ul className="list-disc pl-6 space-y-2">
                <li>Your Profile Information (Name, Email, Phone Number, Profile Picture).</li>
                <li>Your saved Addresses and Locations.</li>
                <li>Any Worker/Labourer profile associated with your account.</li>
                <li>Your in-app chat messages and communication history.</li>
                <li>Your booking history (though we may retain anonymized transaction records for financial compliance as required by law).</li>
              </ul>
            </section>

            <section>
              <h2 className="text-2xl font-bold text-gray-800 mb-4">Data Retention Period</h2>
              <p>
                Once a deletion request is confirmed, your account is deactivated immediately.
                Data is permanently purged from our central systems within 30 days.
                Backups may retain data for up to 90 days before they are overwritten.
              </p>
            </section>

            <section>
              <h2 className="text-2xl font-bold text-gray-800 mb-4">Contact</h2>
              <p>If you have any questions regarding your data, please contact us:</p>
              <ul className="list-none pl-0 space-y-1 mt-2">
                <li><strong>Developer:</strong> Lavish</li>
                <li><strong>App Name:</strong> Will</li>
                <li><strong>Email:</strong> <span className="text-blue-600">templavish9@gmail.com</span></li>
              </ul>
            </section>
          </div>
        </div>
      </div>
    </div>
  );
};

export default DataDeletion;
