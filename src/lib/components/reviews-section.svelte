<script>
    import { reveal } from "$lib/reveal";
    import { scrollTo } from "$lib/scroll";
    import ActionButton from "./shared/action-button.svelte";
    import ReviewBubble from "./review-bubble.svelte";
    const list = [
        {
            text: 'I had an amazing experience at Studio 4 Hair Salon with Kuya John! My haircut was exactly what I wanted and the hair spa treatment was so relaxing.',
            author: 'Josefa'
        },
        {
            text: 'John is the best. I have been a loyal customer for 5 years. He has a great eye for hair fashion and style... who puts his heart and soul in his work. The result always makes me happy!',
            author: 'Marielle'
        },
        {
            // Michael's review is featured in the hero.
            text: 'Great service. Great ambience. A salon that will surely put a smile on your face.',
            author: 'Aileen C.'
        },
        {
            text: 'Highly recommended. I just gave John a brief idea of what I wanted, and he nailed it perfectly. His expertise and attention to detail are impressive.',
            author: 'Elizah May'
        },
    ];
</script>

<section id="reviews-section" aria-labelledby="reviews-heading">
    <div class="wrapper">
        <div class="header reveal-section from-bottom staggered" use:reveal>
            <h2 id="reviews-heading">What my clients say</h2>
        </div>
        <div class="content">
            {#each list as data}
            <ReviewBubble {data} />
            {/each}
        </div>
    </div>

    <div class="actions reveal-section from-bottom" use:reveal>
        <ActionButton label="Come and visit" icon="arrow-down" variant="text"
            onclick={() => scrollTo('visit-section')}
        />
    </div>
</section>

<style>
    #reviews-section {
        padding: 4rem 0 6rem;
        background-color: var(--color-accent-50);
        scroll-margin-top: 2rem;
    }
    .wrapper {
        width: min(90%, 110rem);
        margin: 0 auto;
        display: flex;
        flex-direction: column;
        gap: 2rem;
    }
    .wrapper > .header {
        display: flex;
        flex-direction: column;
        justify-content: center;
        text-align: center;
        gap: 0.5rem;
    }
    .wrapper > .header > h2 {
        font-size: clamp(2rem, 5vw, 2.75rem);
        font-family: var(--font-serif);
        line-height: 1.15;
    }
    .wrapper > .content {
        display: flex;
        flex-direction: column;
        gap: 1.5rem;
    }
    @media (min-width: 40rem) {
        .wrapper > .content {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            align-items: start;
            gap: 2.5rem 2rem;
        }
    }
    .actions {
        display: flex;
        align-items: center;
        justify-content: center;
        margin-top: 1rem;
    }
</style>
