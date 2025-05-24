<script>
    import { createReviewsData } from "$lib/data/reviews.svelte";
    import { onMount } from "svelte";
    import { crossfade, fade, slide } from "svelte/transition";

    const reviews = createReviewsData();

    const getRandom = () => {
        const MIN = Math.ceil(0);
        const MAX = Math.floor(4);
        return Math.floor(
            Math.random() * (MAX - MIN + 1)
        );
    };

    let count = reviews.list.length;
    let show = $state(true);
    let index = $state(getRandom());
    let review = $derived(reviews.list[index]);
    
    onMount(() => index = getRandom());
    // const delay = () => new Promise((resolve) => setTimeout(resolve, 5000));

    /* (async () => {
        while (index < count) {
            console.log(`LOOP index = ${index}`);
            await delay();
            index < (count - 1) ? index++ : index = 0;
        }
    })(); */
</script>

<section class="wrapper">
    <!-- {#key index} -->
    <div id="review-container" class="review" in:fade={{ duration: 500 }} out:fade={{ duration: 500 }}>
        <div class="text">{review.text}</div>
        <div class="separator"></div>
        <div class="author">{review.author}</div>
    </div>
    <!-- {/key} -->
</section>

<style>
    /* section {
        border: 1px solid red;
    } */
    .review {
        /* border: 1px solid red; */
        width: 90%;
        margin: 0 auto;
        text-align: center;
        font-weight: 200;
        display: flex;
        flex-direction: column;
        gap: 2rem;
        opacity: 1;
        -webkit-transition: all 200ms ease-in-out;
        -moz-transition: all 200ms ease-in-out;
        transition: all 200ms ease-in-out;
        /* transition-delay: 5s; */
    }
    /* .fade {
        opacity: 0;
    } */
    .text{
        font-size: var(--fs-lg);
        font-style: italic;
        font-weight: 100;
        letter-spacing: 1px;
        line-height: 2rem;
        /* margin-bottom: 2rem; */
    }
    @media (min-width: 64rem) {
        .text {
            font-size: var(--fs-xl);
            line-height: 2.5rem;
        }
    }
    .text::before,
    .text::after {
        content: '\0022';
    }
    .separator {
        /* background-color: var(--color-accent); */
        border-bottom: 1px dashed var(--color-accent);
        height: 1px;
        width: 10rem;
        margin: 0 auto;
    }
    .author {
        color: var(--color-grey-dark-03-rgb);
        font-size: var(--fs-sm);
        font-weight: 400;
    }
    @media (min-width: 64rem) {
        .author {
            font-size: var(--fs-md);
        }
    }
</style>