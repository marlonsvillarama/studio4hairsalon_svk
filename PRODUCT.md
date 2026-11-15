# Product

<!-- impeccable:product-schema 1 -->

## Platform

web

## Users

- **Loyal regulars**: long-standing clients, many from Palmerston North's Filipino community (reviews call him "Kuya John"). They already trust John and want to rebook quickly.
- **New local clients**: Palmerston North residents finding the salon for the first time. They need to see who John is, what things cost, and that people like the work before they book.
- Gold Card (SuperGold) holders have their own haircut prices, so seniors are a real audience segment.

## Product Purpose

This is the website and online booking for Studio 4 Hair Salon, an independent salon at 7 George Street, Palmerston North, New Zealand. It introduces the salon and John, shows services with prices and durations, and lets a client book an appointment online. Success means a new visitor turns into a booked client, and a regular can book with as little friction as possible.

## Positioning

Studio 4 is John Fernandez's personal practice. Clients book John himself, his craft and his care, not a rotating team. Reviews say this again and again: loyal for years, he "nailed it" from a brief idea, quality "better than many hairdressers in Auckland."

## Operating Context

- John is the only stylist. Every booking is with him.
- Open Monday to Saturday, 9:30am to 5:00pm. Phone (06) 353-5678, mobile (022) 188-5240, email john@studio4hairsalon.co.nz.
- Booking flow (`/book`) steps: choose services → if more than one service, choose a booking mode ("Book together": soonest slot that fits all services; "Book separately": a date and time per service) → date and time → summary. There are also returning-client login and new-client registration steps.
- Service categories: Haircuts, Colours, Keratin Treatment, Other Services (styling, bridal hair and make-up, eyebrow/eyeliner tattoo), Manicure, Pedicure, Eyebrows, Facial. Each service has a price and a duration, and some prices are "from" (range). Gold Card holders get a reduced price on men's and women's haircuts.

## Capabilities and Constraints

- SvelteKit 2 + Svelte 5 (runes), Tailwind 4, deployed via the Vercel adapter. Phosphor icons.
- Target booking model: **instant booking**. Clients pick a real open slot from John's live availability, and it's confirmed straight away. That backend doesn't exist yet. Availability source, calendar integration, persistence, notifications and payment/deposit policy are **undecided**.
- Auth: a better-auth Google provider is stubbed but not configured. How returning clients get identified is **undecided**.
- Services, prices, opening hours and bookings live in Supabase (project `dfgnmwkmafbjqllhtzgf`, tables prefixed `s4_`), which is the source of truth. John manages them at `/admin`. The website uses only the publishable key.

## Brand Commitments

- **John is the face.** The salon is presented as John's own craft and reputation, never as a faceless brand.
- **Warm, personal voice.** Friendly and familiar, close to family ("Kuya John"), rather than corporate polish.
- **Fair, transparent pricing.** Prices and durations are shown upfront, including Gold Card rates and "from" pricing where a range applies.
- Name: Studio 4 / Studio4. Existing tagline: "Where artistry meets precision."
- John's international background (Dubai, the Philippines, New Zealand, 20+ years) is real content in use. It's supporting material, not a binding headline claim.

## Evidence on Hand

- Client reviews (Josefa, Marielle, Michael, Elizah May, and Aileen C. in the hero) in `src/lib/components/reviews-section.svelte` and `src/lib/components/shared/hero.svelte`.
- Photos of John: `static/images/john*.{jpg,png,avif}`. Salon/hero: `static/images/hero.jpg`, `in-action.jpg`, `poster.jpg`.
- Work gallery: `static/images/gallery/`, plus Facebook-sourced colour and customer photos in `static/images/fb/`.
- Service category imagery: `static/images/{haircut,colour,treatment,makeup}{,-ds}.*`.
- Real Facebook and Instagram URLs are **not yet supplied** (footer links point to `/`). Don't invent review counts, ratings totals, awards or press.

## Product Principles

1. **Book John, not a system.** Every surface should make it feel like you're seeing John, not filling in a form for a business.
2. **Price before commitment.** A client should never reach a booking step without knowing what it costs and how long it takes.
3. **Regulars first in the flow, newcomers first on the page.** The home page earns trust for strangers. The booking flow stays fast for people who already have it.
4. **Real proof only.** Trust comes from actual client words and actual work photos.
