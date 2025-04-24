<script>
    let { title, text = '' } = $props();
</script>

<div class="header wrapper">
    <h3>{title}</h3>
    {#if text}
        <p>{text}</p>
    {/if}
</div>

<style>
    .header {
        /* padding-top: 4rem; */
        text-align: center;
    }
    h3 {
        color: var(--color-grey-dark-03-rgb);
        font-family: var(--font-serif);
        font-size: var(--fs-2xl);
        margin-bottom: 2rem;
    }
    p {
        font-weight: 200;
    }
</style>