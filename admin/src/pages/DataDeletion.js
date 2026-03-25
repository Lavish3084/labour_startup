import React from 'react';
import './PrivacyPolicy.css'; // Reuse existing styles for consistency

const DataDeletion = () => {
    return (
        <div className="policy-container">
            <div className="policy-content">
                <h1>Data Deletion Request</h1>
                <p className="last-updated">Last Updated: March 25, 2026</p>

                <p>
                    At <strong>Will</strong>, we value your privacy and give you full control over your data.
                    You can request the deletion of your account and all associated data at any time.
                </p>

                <h2>How to Request Data Deletion</h2>
                <p>You can request to delete your data through the following methods:</p>

                <div className="steps-container">
                    <h3>Method 1: In-App Deletion (Recommended)</h3>
                    <ol>
                        <li>Open the <strong>Will</strong> app on your device.</li>
                        <li>Log in to your account.</li>
                        <li>Go to the <strong>Profile</strong> screen.</li>
                        <li>Scroll to the bottom and tap on <strong>Delete Account</strong>.</li>
                        <li>Confirm the deletion. Your account and all associated data will be removed instantly from our production servers.</li>
                    </ol>

                    <h3>Method 2: Email Request</h3>
                    <p>
                        If you are unable to access the app, you can send an email to our support team at:
                        <br />
                        <strong>support@justlavish.tech</strong>
                    </p>
                    <p>Please include "Data Deletion Request" in the subject line and provide the email address associated with your account.</p>
                </div>

                <h2>What Data is Deleted?</h2>
                <p>Upon a successful deletion request, the following data is permanently removed from our active databases:</p>
                <ul>
                    <li>Your Profile Information (Name, Email, Profile Picture).</li>
                    <li>Your saved Addresses and Locations.</li>
                    <li>Any Worker/Labourer profile associated with your account.</li>
                    <li>Your booking history (though we may retain anonymized transaction records for financial compliance as required by law).</li>
                </ul>

                <h2>Data Retention Period</h2>
                <p>
                    Once a deletion request is confirmed, your account is deactivated immediately.
                    Data is permanently purged from our central systems within 30 days.
                    Backups may retain data for up to 90 days before they are overwritten.
                </p>

                <p className="contact-info">
                    If you have any questions regarding your data, please contact us at support@justlavish.tech
                </p>
            </div>
        </div>
    );
};

export default DataDeletion;
