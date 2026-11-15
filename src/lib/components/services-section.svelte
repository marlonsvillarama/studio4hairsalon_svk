<script>
    import { reveal } from "$lib/reveal";
    import { scrollTo } from "$lib/scroll";
    import { startingPrice, goldCardServices, formatPrice } from "$lib/data/services";
    import ActionButton from "./shared/action-button.svelte";

    /** @type {{ catalogue: { categories: any[], services: any[] } }} */
    let { catalogue } = $props();

    // Photo and one-line summary per category. A category added later in
    // Supabase still shows, with a default photo and no summary.
    // Keyed by the category slug in Supabase (s4_categories.slug).
    const details = {
        haircut: { image: 'haircut', blurb: "Men's, women's and under-16 cuts" },
        colours: { image: 'colour', blurb: 'Root colour, full colour and foils' },
        treatment: { image: 'treatment', blurb: 'Hair spa, keratin and straightening' },
        other: { image: 'makeup', blurb: 'Styling, bridal hair and make-up, brow and liner tattoo' },
        manicure: { blurb: 'Cleaning, polish and gel manicures' },
        pedicure: { blurb: 'Cleaning, polish, foot spa and massage' },
        eyebrows: { blurb: 'Shape and tint, eyebrow trio and lash tint' },
        facial: { blurb: 'A relaxing basic facial' },
    };
    let cards = $derived(catalogue.categories
        .map(c => ({
            ...c,
            image: null,
            blurb: '',
            ...details[c.slug],
            from: startingPrice(catalogue.services, c.id),
            gold: goldCardServices(catalogue.services, c.id)
        }))
        .filter(c => Number.isFinite(c.from)));
</script>

<section id="services-section" aria-labelledby="services-heading">
    <div class="wrapper">
        <div class="header reveal-section from-bottom" use:reveal>
            <h2 id="services-heading">What I do</h2>
            <p>
                Cuts, colour, treatments and styling for the whole family. Every appointment
                is with me, from the first chat about what you want to the final finish.
            </p>
        </div>
        <ul class="cards reveal-section from-bottom" use:reveal>
            {#each cards as card (card.id)}
                <li>
                    <a class="card" class:plain={!card.image} href="/book?category={card.id}"
                        style={card.image ? `--img: url(/images/${card.image}-ds.png)` : undefined}>
                        <span class="title">{card.name}</span>
                        <span class="blurb">{card.blurb}</span>
                        <span class="price">{formatPrice(card.from, true)}</span>
                        {#if card.gold.length}
                            <span class="gold">
                                <strong>Gold Card</strong>
                                {card.gold.map(s => `${s.name.replace(/\s+haircut.*$/i, '')} ${formatPrice(s.goldCardPrice)} (usually ${formatPrice(s.price)})`).join(' · ')}
                            </span>
                        {/if}
                        <span class="cta">See prices and book <i class="ph ph-arrow-right" aria-hidden="true"></i></span>
                    </a>
                </li>
            {/each}
        </ul>
        <p class="note">All prices in NZ dollars.</p>
        <div class="actions">
            <ActionButton label="Meet John" icon="arrow-down" variant="text"
                onclick={() => scrollTo('john-section')}
            />
        </div>
    </div>
</section>

<style>
    #services-section {
        padding: 4rem 0 6rem;
        background-color: var(--color-accent-50);
        scroll-margin-top: 2em;
    }
    .wrapper {
        width: min(90%, 110rem);
        margin: 0 auto;
        display: flex;
        flex-direction: column;
        gap: 1rem;
    }
    .wrapper > .header {
        display: flex;
        flex-direction: column;
        justify-content: center;
        text-align: center;
        gap: 0.5rem;
    }
    .wrapper > .header > p {
        color: var(--charcoal);
        line-height: 1.75rem;
        margin: 0 auto;
        width: min(100%, 38rem);
    }
    .wrapper > .header > h2 {
        font-size: clamp(2rem, 5vw, 2.75rem);
        font-family: var(--font-serif);
        line-height: 1.15;
    }
    .wrapper > .cards {
        list-style: none;
        display: grid;
        gap: 1rem;
        margin-top: 1.5rem;
    }
    @media (min-width: 40rem) {
        .wrapper > .cards {
            grid-template-columns: repeat(2, 1fr);
            gap: 1.5rem;
        }
    }
    @media (min-width: 80rem) {
        .wrapper > .cards {
            grid-template-columns: repeat(4, 1fr);
        }
    }
    .card {
        background-image:
            linear-gradient(to bottom, rgba(27, 27, 27, 0.15) 0%, rgba(27, 27, 27, 0.55) 45%, rgba(27, 27, 27, 0.9) 100%),
            var(--img);
        background-position: 70% center;
        background-size: cover;
        color: var(--color-off-white);
        display: flex;
        flex-direction: column;
        justify-content: flex-end;
        gap: 0.375rem;
        min-height: 20rem;
        padding: 1.5rem;
    }
    /* Categories without a photo yet. */
    .card.plain {
        background-image: none;
        background-color: var(--darker);
        min-height: 14rem;
    }
    .card .title {
        font: 400 2rem / 1.1 var(--font-serif);
    }
    .card .blurb {
        font-size: 0.9375rem;
        line-height: 1.4;
        opacity: 0.9;
    }
    .card .price {
        color: var(--color-accent-300);
        display: flex;
        flex-wrap: wrap;
        align-items: baseline;
        gap: 0.25rem 0.75rem;
        font-size: 1.375rem;
        font-weight: 600;
        font-variant-numeric: tabular-nums;
        margin-top: 0.5rem;
    }
    .card .gold {
        color: var(--color-off-white);
        font-size: 0.875rem;
        line-height: 1.4;
    }
    .card .gold > strong {
        color: var(--color-accent-300);
        font-weight: 600;
        margin-right: 0.25rem;
    }
    .card .cta {
        border-top: 1px solid rgba(250, 250, 249, 0.3);
        display: flex;
        align-items: center;
        justify-content: space-between;
        font-size: 0.9375rem;
        font-weight: 600;
        margin-top: 0.75rem;
        padding-top: 0.75rem;
    }
    .card .cta > i {
        font-size: 1.125rem;
        transition: transform 250ms cubic-bezier(0.16, 1, 0.3, 1);
    }
    .card:hover .cta > i {
        transform: translateX(4px);
    }
    .card:hover .cta {
        color: var(--color-accent-300);
    }
    .note {
        color: var(--dark);
        font-size: 0.875rem;
        text-align: center;
    }
    .actions {
        display: flex;
        align-items: center;
        justify-content: center;
        margin-top: 1rem;
    }
</style>