import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';
import App from './App';
import { firebaseConfigured } from './lib/firebase';
import { SetupNeededPage } from './pages/Misc';
import './styles.css';

const root = createRoot(document.getElementById('root')!);

root.render(
  <StrictMode>
    {firebaseConfigured ? (
      <BrowserRouter>
        <App />
      </BrowserRouter>
    ) : (
      <SetupNeededPage />
    )}
  </StrictMode>,
);
