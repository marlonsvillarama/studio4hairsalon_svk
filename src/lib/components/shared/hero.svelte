<script>
    import { scrollTo } from "$lib/scroll";
    import ActionButton from "./action-button.svelte";
</script>

<div class="hero" id="hero">
    <div class="hero-img"></div>
    <div class="hero-content">
        <div class="slogan">
            <h1>
                <!-- Hi, I'm <span class="artistry">John</span>. -->
                Where <span class="artistry">artistry</span> meets perfection.
            </h1>
            <p>
                Cuts, colour and treatments from over 20 years
                behind the chair, right in the heart of Palmerston North.
            </p>
        </div>

        <div class="actions">
            <ActionButton label="Book with John" link="/book" icon="arrow-right" />
            <ActionButton label="See prices" variant="ghost"
                onclick={() => scrollTo('services-section')}
            />
        </div>

        <figure class="quote">
            <blockquote>
                <p>I am very fussy with my hair and the quality and care is absolutely top-notch! Better than many hairdressers in Auckland.</p>
            </blockquote>
            <figcaption>Michael, client</figcaption>
        </figure>
    </div>
</div>

<style>
    .hero {
        /* svh: the visible height with mobile browser toolbars showing. */
        min-height: 100vh;
        min-height: 100svh;
        width: 100%;
        position: relative;
    }
    .hero-img {
        background-image:
            linear-gradient(rgba(0, 0, 0, 0.6), rgba(0, 0, 0, 0.6)),
            url('/images/hero.jpg');
        background-size: cover;
        background-position: 50% center;
        position: absolute;
        inset: 0;
        z-index: -1;
    }
    @media (min-width: 60rem) {
        .hero-img {
            background-image:
                linear-gradient(to right, rgba(0, 0, 0, 0.6) 0%, rgba(0, 0, 0, 0.3) 100%),
                url('/images/hero.jpg');
            background-position: center 28%;
        }
    }
    .hero-content {
        min-height: 100vh;
        min-height: 100svh;
        width: 90%;
        max-width: 110rem;
        margin: 0 auto;
        padding: 6rem 0 4rem;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        gap: 2.5rem;
    }
    .slogan {
        display: flex;
        flex-direction: column;
        align-items: center;
    }
    .slogan > h1 {
        color: var(--color-off-white);
        font: 300 clamp(3.25rem, 10vw, 5rem) var(--font-default);
        letter-spacing: -0.03em;
        line-height: 1;
        text-box: trim-both cap alphabetic;
        text-align: center;
    }
    .slogan > h1 > .artistry {
        color: var(--color-accent-400);
        font-weight: 400;
    }
    .slogan > p {
        color: var(--color-off-white);
        font-size: clamp(1rem, 2.5vw, 1.1875rem);
        line-height: 1.55;
        max-width: 34rem;
        opacity: 0.92;
        text-align: center;
        text-wrap: balance;
        margin-top: 1.5rem;
    }
    .actions {
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        gap: 1rem;
    }
    @media (min-width: 40rem) {
        .actions {
            flex-direction: row;
        }
    }
    .quote {
        color: var(--color-off-white);
        max-width: 32rem;
        text-align: center;
    }
    .quote p {
        font: italic 400 clamp(1rem, 2.2vw, 1.0625rem) / 1.55 var(--font-serif);
        text-wrap: balance;
    }
    .quote p::before {
        content: "\201C";
    }
    .quote p::after {
        content: "\201D";
    }
    .quote figcaption {
        font-size: 0.875rem;
        font-weight: 500;
        margin-top: 0.5rem;
        opacity: 0.85;
    }
    .quote figcaption::before {
        content: "\2014\00a0";
        color: var(--color-accent-400);
    }
</style>
