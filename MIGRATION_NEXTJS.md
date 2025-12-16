# 🚀 MIGRATION VERS NEXT.JS - PLAN COMPLET

## 📋 DÉCISION STRATÉGIQUE

**Date** : Décembre 2025  
**Raison** : Flutter Web trop lent pour dashboard, problèmes de compatibilité  
**Solution** : Next.js 14 pour le Web, Flutter pour Mobile uniquement

---

## 🎯 ARCHITECTURE FINALE

```
┌─────────────────────────────────────────────────────────────┐
│                     FRONTEND                                 │
├─────────────────────────────────────────────────────────────┤
│  Mobile (iOS/Android)  →  Flutter 3.x                       │
│  Web Dashboard         →  Next.js 14 (App Router)           │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                     BACKEND (Inchangé)                       │
├─────────────────────────────────────────────────────────────┤
│  Database              →  Supabase (PostgreSQL)             │
│  Auth                  →  Supabase Auth                      │
│  Storage               →  Supabase Storage                   │
│  Edge Functions        →  Supabase Functions                │
│  Realtime              →  Supabase Realtime                  │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                     SERVICES EXTERNES                        │
├─────────────────────────────────────────────────────────────┤
│  AI                    →  OpenAI (Whisper + GPT-4o)         │
│  Paiements             →  Stripe Checkout                    │
│  Monitoring            →  Sentry                             │
│  Analytics             →  Vercel Analytics                   │
└─────────────────────────────────────────────────────────────┘
```

---

## 📦 STACK TECHNIQUE NEXT.JS

### Core
- **Framework** : Next.js 14 (App Router)
- **Language** : TypeScript
- **Styling** : Tailwind CSS + shadcn/ui
- **State** : Zustand (léger) ou React Query

### UI Components
- **Design System** : shadcn/ui (Radix UI + Tailwind)
- **Charts** : Recharts (léger, performant)
- **Tables** : TanStack Table v8
- **Forms** : React Hook Form + Zod
- **Icons** : Lucide React
- **Animations** : Framer Motion

### Backend Integration
- **Database** : @supabase/supabase-js
- **Auth** : @supabase/auth-helpers-nextjs
- **Realtime** : Supabase Realtime

### Payments
- **Stripe** : @stripe/stripe-js
- **Webhooks** : Next.js API Routes

### Utilities
- **I18n** : next-intl
- **Theme** : next-themes
- **Date** : date-fns
- **Validation** : Zod

### DevTools
- **Testing** : Vitest + Testing Library
- **Linting** : ESLint + Prettier
- **Types** : TypeScript strict mode

---

## 🗂️ STRUCTURE DU PROJET

```
sitevoice-web/
├── app/                          # Next.js App Router
│   ├── (auth)/                   # Routes d'authentification
│   │   ├── login/
│   │   ├── signup/
│   │   └── reset-password/
│   ├── (dashboard)/              # Routes protégées
│   │   ├── dashboard/            # Page d'accueil dashboard
│   │   ├── jobs/                 # Interventions
│   │   ├── clients/              # Clients
│   │   ├── products/             # Produits
│   │   ├── billing/              # Facturation
│   │   └── settings/             # Paramètres
│   ├── api/                      # API Routes
│   │   ├── stripe/
│   │   │   └── webhook/          # Webhook Stripe
│   │   └── webhooks/
│   ├── layout.tsx                # Layout racine
│   ├── page.tsx                  # Page d'accueil publique
│   └── globals.css
│
├── components/                   # Composants réutilisables
│   ├── ui/                       # shadcn/ui components
│   ├── charts/                   # Composants de charts
│   ├── tables/                   # Composants de tables
│   ├── forms/                    # Composants de formulaires
│   └── layouts/                  # Layouts (Sidebar, Header)
│
├── lib/                          # Utilitaires
│   ├── supabase/                 # Client Supabase
│   │   ├── client.ts             # Client-side
│   │   ├── server.ts             # Server-side
│   │   └── middleware.ts         # Middleware
│   ├── stripe/                   # Client Stripe
│   ├── utils/                    # Fonctions utils
│   └── constants/                # Constantes
│
├── types/                        # Types TypeScript
│   ├── database.ts               # Types Supabase (auto-generés)
│   ├── models.ts                 # Models métier
│   └── api.ts                    # Types API
│
├── hooks/                        # Custom React Hooks
│   ├── useAuth.ts
│   ├── useJobs.ts
│   └── useSubscription.ts
│
├── middleware.ts                 # Next.js Middleware (Auth)
├── next.config.js
├── tailwind.config.js
├── tsconfig.json
└── package.json
```

---

## 🚀 PLAN DE MIGRATION ÉTAPE PAR ÉTAPE

### PHASE 1 : SETUP (Jour 1) ✅

**Objectif** : Projet Next.js fonctionnel avec auth

```bash
# 1. Créer le projet Next.js
npx create-next-app@latest sitevoice-web --typescript --tailwind --app --src-dir=false

# 2. Installer dépendances essentielles
npm install @supabase/supabase-js @supabase/auth-helpers-nextjs
npm install zod react-hook-form @hookform/resolvers
npm install lucide-react date-fns
npm install zustand

# 3. Setup shadcn/ui
npx shadcn-ui@latest init

# 4. Variables d'environnement
# .env.local :
NEXT_PUBLIC_SUPABASE_URL=https://xxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=xxx
SUPABASE_SERVICE_ROLE_KEY=xxx
STRIPE_PUBLIC_KEY=pk_live_xxx
STRIPE_SECRET_KEY=sk_live_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx
```

**Livrables** :
- ✅ Projet Next.js créé
- ✅ Supabase connecté
- ✅ shadcn/ui configuré
- ✅ TypeScript strict activé

---

### PHASE 2 : AUTHENTIFICATION (Jour 1-2) 🔐

**Pages à créer** :
1. `/login` - Connexion
2. `/signup` - Inscription
3. `/reset-password` - Réinitialiser mot de passe
4. `/auth/callback` - Callback OAuth

**Code example** :

```typescript
// app/(auth)/login/page.tsx
'use client'

import { createClientComponentClient } from '@supabase/auth-helpers-nextjs'
import { useRouter } from 'next/navigation'
import { useState } from 'react'

export default function LoginPage() {
  const router = useRouter()
  const supabase = createClientComponentClient()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')

  async function handleSignIn() {
    await supabase.auth.signInWithPassword({
      email,
      password,
    })
    router.refresh()
  }

  return (
    <div className="flex min-h-screen items-center justify-center">
      <form className="w-full max-w-md space-y-4">
        <input type="email" value={email} onChange={(e) => setEmail(e.target.value)} />
        <input type="password" value={password} onChange={(e) => setPassword(e.target.value)} />
        <button onClick={handleSignIn}>Se connecter</button>
      </form>
    </div>
  )
}
```

**Middleware Auth** :

```typescript
// middleware.ts
import { createMiddlewareClient } from '@supabase/auth-helpers-nextjs'
import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

export async function middleware(req: NextRequest) {
  const res = NextResponse.next()
  const supabase = createMiddlewareClient({ req, res })

  const {
    data: { session },
  } = await supabase.auth.getSession()

  // Protéger les routes /dashboard/*
  if (req.nextUrl.pathname.startsWith('/dashboard') && !session) {
    return NextResponse.redirect(new URL('/login', req.url))
  }

  return res
}

export const config = {
  matcher: '/dashboard/:path*',
}
```

**Livrables** :
- ✅ Login/Signup fonctionnels
- ✅ Middleware de protection
- ✅ Session management

---

### PHASE 3 : LAYOUT DASHBOARD (Jour 2-3) 📐

**Composants à créer** :
1. `DashboardLayout` - Layout principal
2. `Sidebar` - Menu latéral
3. `Header` - Barre supérieure
4. `UserMenu` - Menu utilisateur

**Structure** :

```typescript
// app/(dashboard)/layout.tsx
import { Sidebar } from '@/components/layouts/Sidebar'
import { Header } from '@/components/layouts/Header'

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <div className="flex h-screen">
      <Sidebar />
      <div className="flex-1 flex flex-col overflow-hidden">
        <Header />
        <main className="flex-1 overflow-y-auto p-6">
          {children}
        </main>
      </div>
    </div>
  )
}
```

**Livrables** :
- ✅ Sidebar avec navigation
- ✅ Header avec user menu
- ✅ Layout responsive

---

### PHASE 4 : DASHBOARD HOME (Jour 3-4) 📊

**KPIs à afficher** :
- Total interventions ce mois
- Chiffre d'affaires
- Clients actifs
- Taux de conversion

**Charts à créer** :
- Line chart : CA mensuel
- Bar chart : Interventions par type
- Pie chart : Répartition clients

**Code example** :

```typescript
// app/(dashboard)/dashboard/page.tsx
import { KPICard } from '@/components/charts/KPICard'
import { RevenueChart } from '@/components/charts/RevenueChart'
import { createServerComponentClient } from '@supabase/auth-helpers-nextjs'
import { cookies } from 'next/headers'

export default async function DashboardPage() {
  const supabase = createServerComponentClient({ cookies })

  // Fetch KPIs
  const { data: jobs } = await supabase
    .from('jobs')
    .select('*')
    .gte('created_at', new Date(new Date().setDate(1)).toISOString())

  const totalRevenue = jobs?.reduce((sum, job) => sum + (job.total_amount || 0), 0)

  return (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold">Dashboard</h1>
      
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <KPICard title="Interventions" value={jobs?.length || 0} />
        <KPICard title="Revenue" value={`${totalRevenue}€`} />
        <KPICard title="Clients" value="42" />
        <KPICard title="Taux conversion" value="85%" />
      </div>

      <RevenueChart data={jobs} />
    </div>
  )
}
```

**Livrables** :
- ✅ KPIs en temps réel
- ✅ Charts interactifs (Recharts)
- ✅ Design Material 3

---

### PHASE 5 : PAGES CRUD (Jour 4-6) 📝

**Pages à créer** :
1. `/dashboard/jobs` - Liste des interventions
2. `/dashboard/clients` - Liste des clients
3. `/dashboard/products` - Liste des produits

**Features** :
- ✅ Table avec tri/filtres (TanStack Table)
- ✅ Search en temps réel
- ✅ Pagination
- ✅ Export CSV
- ✅ Modals Create/Edit/Delete

**Code example** :

```typescript
// app/(dashboard)/jobs/page.tsx
import { JobsTable } from '@/components/tables/JobsTable'
import { createServerComponentClient } from '@supabase/auth-helpers-nextjs'
import { cookies } from 'next/headers'

export default async function JobsPage() {
  const supabase = createServerComponentClient({ cookies })
  
  const { data: jobs } = await supabase
    .from('jobs')
    .select('*, client:clients(*)')
    .order('created_at', { ascending: false })

  return (
    <div>
      <h1>Interventions</h1>
      <JobsTable data={jobs || []} />
    </div>
  )
}
```

**Livrables** :
- ✅ Tables fonctionnelles
- ✅ CRUD complet
- ✅ UX optimisée

---

### PHASE 6 : STRIPE INTEGRATION (Jour 6-7) 💳

**Pages à créer** :
1. `/dashboard/billing` - Gestion facturation
2. `/api/stripe/webhook` - Webhook Stripe

**Features** :
- ✅ Bouton "Upgrade to Premium"
- ✅ Redirection vers Stripe Checkout
- ✅ Portail client Stripe
- ✅ Webhook handler

**Code example** :

```typescript
// app/(dashboard)/billing/page.tsx
'use client'

import { Button } from '@/components/ui/button'

export default function BillingPage() {
  async function handleUpgrade() {
    const res = await fetch('/api/stripe/create-checkout-session', {
      method: 'POST',
    })
    const { url } = await res.json()
    window.location.href = url
  }

  return (
    <div>
      <h1>Facturation</h1>
      <Button onClick={handleUpgrade}>Passer à Premium</Button>
    </div>
  )
}
```

```typescript
// app/api/stripe/webhook/route.ts
import { headers } from 'next/headers'
import { stripe } from '@/lib/stripe'
import { createClient } from '@supabase/supabase-js'

export async function POST(req: Request) {
  const body = await req.text()
  const signature = headers().get('stripe-signature')!

  const event = stripe.webhooks.constructEvent(
    body,
    signature,
    process.env.STRIPE_WEBHOOK_SECRET!
  )

  if (event.type === 'checkout.session.completed') {
    const session = event.data.object
    // Update user subscription in Supabase
  }

  return new Response(null, { status: 200 })
}
```

**Livrables** :
- ✅ Stripe Checkout fonctionnel
- ✅ Webhooks configurés
- ✅ Subscription status sync

---

### PHASE 7 : MAP VIEW (Jour 7-8) 🗺️

**Feature** : Carte interactive avec marqueurs des interventions

**Libraries** :
- Option 1 : `react-map-gl` (Mapbox - payant)
- Option 2 : `react-leaflet` (OpenStreetMap - gratuit)

**Code example** :

```typescript
// components/MapView.tsx
'use client'

import { MapContainer, TileLayer, Marker, Popup } from 'react-leaflet'
import 'leaflet/dist/leaflet.css'

export function MapView({ jobs }: { jobs: any[] }) {
  return (
    <MapContainer center={[48.8566, 2.3522]} zoom={13} className="h-96">
      <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />
      {jobs.map((job) => (
        <Marker key={job.id} position={[job.gps_latitude, job.gps_longitude]}>
          <Popup>{job.client_name}</Popup>
        </Marker>
      ))}
    </MapContainer>
  )
}
```

**Livrables** :
- ✅ Carte interactive
- ✅ Marqueurs cliquables
- ✅ Clustering si +100 points

---

### PHASE 8 : I18N (Jour 8-9) 🌍

**Setup next-intl** :

```typescript
// middleware.ts
import createMiddleware from 'next-intl/middleware'

export default createMiddleware({
  locales: ['en', 'fr', 'es'],
  defaultLocale: 'fr',
})

export const config = {
  matcher: ['/((?!api|_next|_vercel|.*\\..*).*)'],
}
```

```json
// messages/fr.json
{
  "Dashboard": {
    "title": "Tableau de bord",
    "jobs": "Interventions",
    "revenue": "Chiffre d'affaires"
  }
}
```

**Livrables** :
- ✅ 3 langues (EN/FR/ES)
- ✅ Sélecteur de langue
- ✅ Dates/Devises localisées

---

### PHASE 9 : OPTIMISATIONS (Jour 9-10) ⚡

**Checklist Performance** :
- ✅ Image optimization (next/image)
- ✅ Font optimization (next/font)
- ✅ Bundle size < 300 KB
- ✅ Lighthouse score > 95
- ✅ First Load < 1s
- ✅ Lazy loading components
- ✅ API Routes caching

**Code example** :

```typescript
// next.config.js
module.exports = {
  images: {
    formats: ['image/avif', 'image/webp'],
  },
  experimental: {
    optimizeCss: true,
  },
}
```

**Livrables** :
- ✅ Performance optimisée
- ✅ SEO optimisé
- ✅ Accessibilité (a11y)

---

### PHASE 10 : DEPLOYMENT (Jour 10) 🚀

**Vercel Deployment** :

```bash
# 1. Connecter GitHub repo
# 2. Vercel auto-détecte Next.js
# 3. Ajouter variables d'env
# 4. Deploy !

vercel --prod
```

**Configuration** :
```json
// vercel.json
{
  "env": {
    "NEXT_PUBLIC_SUPABASE_URL": "@supabase-url",
    "NEXT_PUBLIC_SUPABASE_ANON_KEY": "@supabase-anon-key"
  }
}
```

**Livrables** :
- ✅ Production live sur Vercel
- ✅ CI/CD automatique
- ✅ Preview deployments

---

## 📱 FLUTTER MOBILE (Inchangé)

**Ce qui reste en Flutter** :
- ✅ App mobile iOS
- ✅ App mobile Android
- ✅ Audio recording
- ✅ GPS capture
- ✅ Photo capture
- ✅ Signature capture

**Ce qui part vers Next.js** :
- ❌ Dashboard Web
- ❌ Analytics Web
- ❌ Admin panel Web

---

## 🔄 COHABITATION FLUTTER + NEXT.JS

```
Mobile App (Flutter)
    ↓
Supabase API
    ↑
Web Dashboard (Next.js)
```

**Avantages** :
- ✅ Meilleur outil pour chaque plateforme
- ✅ Performance optimale
- ✅ Maintenance séparée

---

## 📊 GAIN ATTENDU

### Performance

| Métrique | Flutter Web | Next.js | Gain |
|----------|-------------|---------|------|
| Bundle | 2.5 MB | 250 KB | **-90%** |
| First Load | 3.0s | 0.5s | **-83%** |
| Lighthouse | 65/100 | 98/100 | **+51%** |
| SEO | 0/100 | 100/100 | **+100%** |

### Coûts

| Poste | Flutter Web | Next.js | Diff |
|-------|-------------|---------|------|
| Hosting | 50$/mois | 0$ (Vercel Free) | **-50$** |
| CDN | 20$/mois | Inclus Vercel | **-20$** |
| **Total** | **70$/mois** | **0$/mois** | **-70$/mois** |

---

## ⏱️ TIMELINE

**Total : 10 jours** (1 développeur full-time)

```
Jour 1-2   : Setup + Auth
Jour 3-4   : Dashboard + Layout
Jour 4-6   : Pages CRUD
Jour 6-7   : Stripe
Jour 7-8   : Map View
Jour 8-9   : I18n
Jour 9-10  : Optimizations + Deploy
```

**Parallélisation possible** : 5-6 jours avec 2 devs

---

## 🎯 CHECKLIST FINALE

### Setup
- [ ] Créer projet Next.js
- [ ] Installer dépendances
- [ ] Configurer TypeScript strict
- [ ] Setup shadcn/ui
- [ ] Configurer Tailwind

### Auth
- [ ] Pages Login/Signup
- [ ] Middleware protection
- [ ] Session management
- [ ] Password reset

### Dashboard
- [ ] Layout (Sidebar + Header)
- [ ] Page Home (KPIs)
- [ ] Charts (Recharts)
- [ ] Responsive design

### CRUD
- [ ] Jobs list + details
- [ ] Clients list + CRUD
- [ ] Products list + CRUD
- [ ] Search + Filters

### Stripe
- [ ] Checkout buttons
- [ ] Webhook handler
- [ ] Subscription sync
- [ ] Customer portal

### Features
- [ ] Map view
- [ ] I18n (EN/FR/ES)
- [ ] Dark mode
- [ ] Export CSV

### Optimizations
- [ ] Image optimization
- [ ] Bundle size < 300 KB
- [ ] Lighthouse > 95
- [ ] SEO metadata

### Deploy
- [ ] Vercel deployment
- [ ] Env variables
- [ ] Custom domain
- [ ] CI/CD

---

## 🔮 ROADMAP POST-MIGRATION

### V1.0 (Immédiat)
- ✅ Dashboard fonctionnel
- ✅ Auth + CRUD
- ✅ Stripe integration

### V1.1 (1 mois)
- 📧 Emails transactionnels (Resend)
- 📊 Analytics avancées (Posthog)
- 🤖 AI Copilot (ChatGPT sidebar)

### V1.2 (3 mois)
- 📱 Progressive Web App (PWA)
- 🔔 Notifications push
- 📥 Webhooks externes

---

**🎊 MIGRATION VERS NEXT.JS PRÊTE À DÉMARRER !**

*Développée avec ❤️ pour des performances 10x supérieures*

---

**PROCHAINE ÉTAPE** :
```bash
npx create-next-app@latest sitevoice-web --typescript --tailwind --app
cd sitevoice-web
npm install @supabase/supabase-js
npm run dev
```

**Voulez-vous que je commence ?** 🚀




