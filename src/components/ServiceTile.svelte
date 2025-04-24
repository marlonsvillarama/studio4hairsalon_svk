<script>
    let { image, label, description } = $props();
</script>

<div class="container">
    <img src={image} alt={label}>
    <div class="text">
        <h3>{label}</h3>
        <p>{description}</p>
    </div>
</div>

<style>
    .container {
        border: 0px solid red;
        /* display: flex;
        flex-direction: column;
        gap: 0.25rem; */
        cursor: pointer;
        transition: all 150ms ease-in-out;
    }
    .container:hover {
        opacity: 1;
        box-shadow: var(--box-shadow);
        /* transform: translateY(-2px); */
    }
    img {
        width: 100%;
        /* height: 100%; */
        border: 0;
        margin-bottom: 1rem;
        opacity: 0.9;
        transition: all 100ms ease-in-out;
    }
    .text {
        color: var(--color-grey-dark-03-rgb);
    }
    .text h3 {
        /* color: var(--color-grey-dark-03); */
        font-family: var(--font-default);
        font-size: var(--fs-xl);
        /* font-style: italic; */
        font-weight: 500;
        letter-spacing: 0.25px;
        text-align: center;
        margin-bottom: 0.5rem;
    }
    .text p {
        color: var(--color-grey-dark-03-rgb);
        font-family: var(--font-default);
        font-size: var(--fs-sm);
        font-weight: 200;
        padding: 0 1.5rem 1.5rem;
    }
</style>