<script>
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
            text: 'I am very fussy with my hair and the quality and care is absolutely top-notch! Better than many hairdressers in Auckland. Thank you!',
            author: 'Michael'
        },
        {
            text: 'Highly recommended. I just gave John a brief idea of what I wanted, and he nailed it perfectly. His expertise and attention to detail are impressive.',
            author: 'Elizah May'
        },
    ];
</script>

<section>
    <div class="wrapper">
        <div class="header">
            <span>Our Reviews</span>
            <h2>What Our Clients Say</h2>
        </div>
        <div class="content">
            {#each list as data}
            <ReviewBubble {data} />
            {/each}
        </div>
    </div>
</section>

<style>
    section {
        /* border: 1px solid green; */
        padding: 4rem 0 8rem;
        height: 40rem;
        /* background-color: var(--color-accent-800); */
        background-image: url(/images/pattern-001.svg);
    }
    .wrapper {
        /* background-color: var(--color-off-white); */
        width: min(95%, 110rem);
        margin: 0 auto;
        display: flex;
        flex-direction: column;
        gap: 2rem;
    }
    .wrapper > .header > span {
        font-size: 0.875rem;
        /* font-weight: 300; */
        opacity: 0.6;
        text-transform: uppercase;
    }
    .wrapper > .header > h2 {
        font-size: 3.5rem;
        /* font-family: var; */
        line-height: 3.5rem;
    }
    .wrapper > .content {
        display: grid;
        grid-template-columns: repeat(4, 1fr);
        gap: 1rem;
    }
</style>
