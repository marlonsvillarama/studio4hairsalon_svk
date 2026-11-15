<script>
    import { reveal } from "$lib/reveal";
    import { scrollTo } from "$lib/scroll";
    import ActionButton from "./shared/action-button.svelte";
</script>

<section id="john-section" aria-labelledby="john-heading">
    <div class="wrapper">
        <div class="header reveal-section from-bottom staggered" use:reveal>
            <h2 id="john-heading">Hi, I'm John</h2>
            <p>
                I've been doing hair for over 20 years, in salons across Dubai, the Philippines
                and now here in New Zealand.
            </p>
            <p>
                Along the way I've picked up techniques and trends from all over the world. But what
                matters most to me is simple: listening to what you want, and giving you a look
                that suits you.
            </p>
            <p>
                When you book at Studio 4, you're booking me. Every appointment, every time.
            </p>
            <ActionButton label="Read what my clients say" icon="arrow-down" variant="text"
                onclick={() => scrollTo('reviews-section')}
            />
        </div>
        <div class="john-img reveal-section from-bottom staggered" use:reveal
            role="img" aria-label="Portrait of John Fernandez"></div>
    </div>
</section>

<style>
    #john-section {
        padding: 4rem 0 6rem;
        scroll-margin-top: 2em;
    }
    .wrapper {
        width: min(90%, 60rem);
        margin: 0 auto;
        display: flex;
        flex-direction: column;
        align-items: center;
        gap: 3rem;
    }
    .wrapper > .header {
        display: flex;
        flex-direction: column;
        justify-content: flex-start;
        gap: 0.5rem;
        margin: 0 auto;
        width: min(40rem, 100%);
    }
    .wrapper > .header > h2 {
        text-align: center;
        font: 600 2.5rem var(--font-serif);
    }
    .wrapper > .header > p {
        color: var(--charcoal);
        line-height: 1.75rem;
        margin: 0.5rem 0;
        width: min(100%, 40rem);
    }

    .wrapper > .john-img {
        background-image: url(/images/john.avif);
        background-size: cover;
        background-position: 100% center;
        border-top-left-radius: 4rem;
        border-bottom-right-radius: 4rem;
        width: min(25rem, 100%);
        height: 35rem;
        transform: scaleX(-1);
    }
    @media (min-width: 60rem) {
        .wrapper {
            flex-direction: row;
            width: min(90%, 60rem);
        }
        .wrapper > .john-img {
            order: 1;
        }
        .wrapper > .header {
            order: 2;
        }
        .wrapper > .header > h2 {
            text-align: start;
            font: 600 3.5rem var(--font-serif);
        }
    }
</style>