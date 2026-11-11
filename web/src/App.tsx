import { lazy, Suspense } from 'react';
import { Route, Routes } from 'react-router-dom';
import { PageLoader } from './components/Bits';
import EffectsCanvas from './components/EffectsCanvas';
import Layout, { ScrollToTop } from './components/Layout';
import RequireAuth from './components/RequireAuth';
import { AuthProvider } from './context/AuthContext';
import { CartProvider } from './context/CartContext';
import { StoreProvider } from './context/StoreContext';
import { ToastProvider } from './context/ToastContext';
import Catalog from './pages/Catalog';
import Home from './pages/Home';
import ProductPage from './pages/ProductPage';
import { NotFoundPage } from './pages/Misc';

// Páginas que se cargan solo cuando se necesitan (la web inicial pesa menos)
const CartPage = lazy(() => import('./pages/CartPage'));
const Checkout = lazy(() => import('./pages/Checkout'));
const LoginPage = lazy(() => import('./pages/AuthPages').then((m) => ({ default: m.LoginPage })));
const RegisterPage = lazy(() => import('./pages/AuthPages').then((m) => ({ default: m.RegisterPage })));
const ForgotPasswordPage = lazy(() => import('./pages/AuthPages').then((m) => ({ default: m.ForgotPasswordPage })));
const MyOrdersPage = lazy(() => import('./pages/AccountPages').then((m) => ({ default: m.MyOrdersPage })));
const OrderPage = lazy(() => import('./pages/AccountPages').then((m) => ({ default: m.OrderPage })));
const ProfilePage = lazy(() => import('./pages/AccountPages').then((m) => ({ default: m.ProfilePage })));

export default function App() {
  return (
    <ToastProvider>
      <StoreProvider>
        <AuthProvider>
          <CartProvider>
            <ScrollToTop />
            <EffectsCanvas />
            <Layout>
              <Suspense fallback={<PageLoader />}>
                <Routes>
                  <Route path="/" element={<Home />} />
                  <Route path="/catalogo" element={<Catalog />} />
                  <Route path="/producto/:id" element={<ProductPage />} />
                  <Route path="/carrito" element={<CartPage />} />
                  <Route path="/ingresar" element={<LoginPage />} />
                  <Route path="/registro" element={<RegisterPage />} />
                  <Route path="/recuperar" element={<ForgotPasswordPage />} />
                  <Route
                    path="/checkout"
                    element={
                      <RequireAuth>
                        <Checkout />
                      </RequireAuth>
                    }
                  />
                  <Route
                    path="/mis-pedidos"
                    element={
                      <RequireAuth>
                        <MyOrdersPage />
                      </RequireAuth>
                    }
                  />
                  <Route
                    path="/pedido/:id"
                    element={
                      <RequireAuth>
                        <OrderPage />
                      </RequireAuth>
                    }
                  />
                  <Route
                    path="/perfil"
                    element={
                      <RequireAuth>
                        <ProfilePage />
                      </RequireAuth>
                    }
                  />
                  <Route path="*" element={<NotFoundPage />} />
                </Routes>
              </Suspense>
            </Layout>
          </CartProvider>
        </AuthProvider>
      </StoreProvider>
    </ToastProvider>
  );
}
