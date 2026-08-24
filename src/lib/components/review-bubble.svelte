<script>
    let { data } = $props();
</script>

<div class="review">
    <div class="bubble">
        <div class="stars">
            {#each { length: 5} as _}
            <i class="ph-fill ph-star"></i>
            {/each}
        </div>
        <div class="content">
            <i class="ph-fill ph-quotes"></i>
            <p>{data.text}</p>
        </div>
    </div>
    <div class="author">
        <div class="avatar">{data.author[0]}</div>
        <div class="name">{data.author}</div>
    </div>
</div>

<style>
    .review {
        display: flex;
        flex-direction: column;
    }
    .review > .bubble{
        background-color: var(--color-off-white);
        position: relative;
        /* border-radius: 0.25rem; */
        box-shadow: rgba(0, 0, 0, 0.24) 0px 3px 8px;
        padding: 1.25rem 1.5rem;
        height: 20rem;
        display: flex;
        flex-direction: column;
        gap: 1rem;
    }
    .review > .bubble::after {
        content: "";
        position: absolute;
        bottom: 0;
        left: 30%;
        width: 0;
        height: 0;
        border: 2rem solid transparent;
        border-top-color: var(--color-off-white);
        border-bottom: 0;
        border-left: 0;
        margin-left: -1rem;
        margin-bottom: -2rem;
    }
    .review > .bubble > .stars {
        display: flex;
        align-items: center;
        color: var(--color-accent-400);
        font-size: 1.5rem;
    }
    .review > .bubble > .content {
        display: flex;
        align-items: flex-start;
        gap: 1rem;
    }
    .review > .bubble > .content > i {
        font-size: 2.5rem;
        opacity: 0.2;
    }
    .review > .author {
        display: flex;
        align-items: center;
        gap: 3rem;
        padding: 1rem;
    }
    .review > .author > .avatar {
        height: 3rem;
        width: 3rem;
        background-color: var(--color-accent-600);
        border-radius: 50%;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 1.25rem;
        color: var(--color-off-white);
    }
</style>