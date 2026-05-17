'use client';

import { useEffect, useState } from 'react';

export default function CallbackPage() {
  const [status, setStatus] = useState('processing');

  useEffect(() => {
    // Check if this is an OAuth callback with a code
    const params = new URLSearchParams(window.location.search);
    const code = params.get('code');
    const error = params.get('error');

    if (error) {
      setStatus('error');
    } else if (code) {
      setStatus('success');
    } else {
      setStatus('unknown');
    }
  }, []);

  return (
    <div style={{
      display: 'flex',
      justifyContent: 'center',
      alignItems: 'center',
      minHeight: '100vh',
      background: '#000',
      color: '#ededed',
      fontFamily: "'Geist', -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif",
    }}>
      <div style={{
        textAlign: 'center',
        padding: '48px',
        background: '#0a0a0a',
        border: '1px solid rgba(255,255,255,0.08)',
        borderRadius: '16px',
        maxWidth: '440px',
        width: '90%',
      }}>
        {status === 'success' && (
          <>
            <div style={{ fontSize: '48px', marginBottom: '16px', color: '#10b981' }}>✓</div>
            <h2 style={{ margin: '0 0 8px', fontWeight: 500, fontSize: '20px' }}>
              Authentication Complete
            </h2>
            <p style={{ color: '#888', margin: '0 0 24px', fontSize: '14px', lineHeight: '1.5' }}>
              Return to the Jawhar app to continue your journey.
            </p>
            <p style={{ color: '#555', margin: 0, fontSize: '12px' }}>
              You can safely close this tab.
            </p>
          </>
        )}

        {status === 'error' && (
          <>
            <div style={{ fontSize: '48px', marginBottom: '16px', color: '#ef4444' }}>✕</div>
            <h2 style={{ margin: '0 0 8px', fontWeight: 500, fontSize: '20px' }}>
              Sign-in Cancelled
            </h2>
            <p style={{ color: '#888', margin: '0 0 24px', fontSize: '14px', lineHeight: '1.5' }}>
              The sign-in was cancelled or denied. Please try again from the Jawhar app.
            </p>
            <p style={{ color: '#555', margin: 0, fontSize: '12px' }}>
              You can safely close this tab.
            </p>
          </>
        )}

        {status === 'processing' && (
          <>
            <div style={{ fontSize: '48px', marginBottom: '16px', opacity: 0.5 }}>◇</div>
            <h2 style={{ margin: '0 0 8px', fontWeight: 500, fontSize: '20px' }}>
              Processing...
            </h2>
            <p style={{ color: '#888', margin: 0, fontSize: '14px' }}>
              Completing authentication with Jawhar.
            </p>
          </>
        )}

        {status === 'unknown' && (
          <>
            <div style={{ fontSize: '48px', marginBottom: '16px', opacity: 0.5 }}>◇</div>
            <h2 style={{ margin: '0 0 8px', fontWeight: 500, fontSize: '20px' }}>
              Jawhar
            </h2>
            <p style={{ color: '#888', margin: '0 0 24px', fontSize: '14px', lineHeight: '1.5' }}>
              This page handles authentication callbacks.
              Please sign in from the Jawhar app.
            </p>
          </>
        )}
      </div>
    </div>
  );
}
