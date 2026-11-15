<script>
    import { reveal } from "$lib/reveal";
    let { data } = $props();
</script>

<figure class="review reveal-section from-bottom staggered" use:reveal>
    <blockquote class="bubble">
        <p>{data.text}</p>
    </blockquote>
    <figcaption class="author">{data.author}</figcaption>
</figure>

<style>
    .review {
        display: flex;
        flex-direction: column;
    }
    .bubble {
        background-color: var(--color-off-white);
        box-shadow: 0 6px 18px -8px rgba(27, 27, 27, 0.28), 0 1px 3px rgba(27, 27, 27, 0.08);
        padding: 1.75rem 1.75rem 2rem;
        position: relative;
    }
    /* The speech-bubble tail, pointing at the client's name. */
    .bubble::after {
        content: "";
        position: absolute;
        bottom: -1.25rem;
        left: 2.25rem;
        border: 1.25rem solid transparent;
        border-top-color: var(--color-off-white);
        border-bottom: 0;
        border-left: 0;
    }
    .bubble > p {
        color: var(--darkest);
        font: 400 clamp(1.0625rem, 1.6vw, 1.1875rem) / 1.6 var(--font-serif);
        text-wrap: pretty;
    }
    .bubble > p::before {
        content: "\201C";
        color: var(--color-accent-700);
    }
    .bubble > p::after {
        content: "\201D";
        color: var(--color-accent-700);
    }
    .author {
        color: var(--darkest);
        font-weight: 600;
        padding: 1.75rem 0 0 2.25rem;
    }
</style>
