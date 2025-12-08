<script>
    let { image, label, description } = $props();
</script>

<div class="container">
    <img src={image} alt={label}>
    <div class="text">
        <h3>{label}</h3>
        <!-- <p>{description}</p> -->
    </div>
</div>

<style>
    .container {
        /* border: 1px solid green; */
        /* display: flex;
        flex-direction: column;
        gap: 0.25rem; */
        cursor: pointer;
        transition: all 150ms ease-in-out;
    }
    .container:hover {
        transform: translateY(-1px);
    }
    .container:hover > img {
        opacity: 1;
        box-shadow: var(--box-shadow);
        /* transform: translateY(-2px); */
    }
    img {
        width: 100%;
        /* height: 100%; */
        border: 0;
        border-radius: 0.5rem;
        margin-bottom: 0.5rem;
        opacity: 0.9;
        transition: all 100ms ease-in-out;
    }
    @media (min-width: 40rem) {
        img {
            margin-bottom: 0.75rem;
        }
    }
    .text {
        color: var(--color-grey-dark-03-rgb);
    }
    .text h3 {
        /* color: var(--color-grey-dark-03); */
        font-family: var(--font-default);
        font-size: var(--fs-lg);
        /* font-style: italic; */
        font-weight: 500;
        letter-spacing: 0.25px;
        text-align: center;
        margin-bottom: 0.5rem;
    }
    @media (min-width: 40rem) {
        .text h3 {
            font-size: var(--fs-lg);
        }
    }
    .text p {
        color: var(--color-grey-dark-03-rgb);
        font-family: var(--font-default);
        font-size: var(--fs-xs);
        font-weight: 200;
        padding: 0 1.5rem;
    }
    @media (min-width: 40rem) {
        .text p {
            font-size: var(--fs-xs);
        }
    }
</style>