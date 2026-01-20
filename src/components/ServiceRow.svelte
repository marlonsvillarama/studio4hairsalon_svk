<script>
    let { data, flip } = $props();
</script>

<section class="wrapper" id="{data.link}">
    {#if data.image}
        <img src={data.image} alt={data.name}>
    {:else}
        <div class="logo">Studio 4</div>
    {/if}
    <div class="list">
        <h3>{data.name}</h3>
        {#each data.services as item}
        <div class="item">
            <div>
                <span class="title">{item.name}</span>
                <span class="price"><span class="range">{item.range === true ? `starts at ` : ''}</span>{item.price}</span>
                <!-- <br/> -->
                <!-- <span class="text">{item.description}</span> -->
            </div>
            <a href="/book?id={item.id}">Book now</a>
            <!-- <div>
            </div> -->
        </div>
        {/each}
    </div>
</section>

<style>
    section {
        /* border: 1px solid red; */
        display: flex;
        flex-direction: column;
        gap: 2rem;
    }
    @media (min-width: 64rem) {
        section {
            display: grid;
            gap: 4rem;
            grid-template-columns: 35% calc(65% - 4rem);
            align-items: flex-start;
        }
    }
    img {
        width: 100%;
        border-radius: 0.5rem;
    }
    h3 {
        color: var(--color-grey-dark-03-rgb);
        font-family: var(--font-serif);
        font-size: var(--fs-xl);
        font-weight: 600;
        padding-bottom: 0.5rem;
        margin-bottom: 1rem;
        border-bottom: 2px solid var(--color-accent);
        /* display: inline-block; */
     }
    .item {
        padding: 0 0 1rem;
        /* margin: 0 2rem; */
        /* cursor: pointer; */
        /* border: 1px solid red; */
        transition: all 100ms ease-in-out;
        display: flex;
        flex-direction: column;
        /* justify-content: space-between; */
        /* align-items: center; */
        gap: 0.5rem;
        font-size: var(--fs-sm);
        font-weight: 400;
    }
    @media (min-width: 30rem) {
        .item {
            flex-direction: row;
            justify-content: space-between;
            align-items: center;
            gap: 1rem;
        }
    }
    @media (min-width: 40rem) {
        .item {
            flex-direction: row;
            justify-content: space-between;
            align-items: center;
            gap: 2rem;
        }
    }
    @media (min-width: 64rem) {
        .item {
            padding: 1rem 1.5rem;
        }
    }
    .item:not(:last-child) {
        border-bottom: 1px dashed var(--color-accent);
        margin-bottom: 1rem;
    }

    .item > *:first-child {
        /* border: 1px solid red; */
        flex-grow: 1;
        display: flex;
        flex-direction: row;
        align-items: center;
        justify-content: space-between;
        /* gap: 0.25rem; */
    }
    @media (min-width: 30rem) {
        .item > *:first-child {
            flex-direction: row;
            justify-content: space-between;
        }
    }
    @media (min-width: 40rem) {
        .item > *:first-child {
            flex-direction: row;
            justify-content: space-between;
            align-items: center;
        }
    }

    .title {
        font-size: var(--fs-sm);
    }

    .item a {
        display: inline-block;
        padding: 0.25rem 1.5rem;
        background-color: var(--color-bg-btn);
        border-radius: 0.25rem;
        cursor: pointer;
        font-size: var(--fs-sm);
        font-weight: 500;
        text-align: center;
        transition: all 150ms ease-in-out;
    }
    /* .item:hover {
        border: 1px solid var(--color-accent);
        border-radius: 0.5rem;
        box-shadow: var(--box-shadow);
    } */
    /* .item .title {
        font-size: var(--fs-sm);
        /* font-weight: 500; *!/
        font-weight: 200;
        letter-spacing: 0.25px;
    } */
    /* .item .text {
        color: var(--color-grey-dark-03-rgb);
        font-size: var(--fs-xs);
        font-weight: 300;
    } */
    /* .item > :last-child {
        display: flex;
        flex-direction: row;
        gap: 2rem;
        align-items: center;
    } */
    /* .price {
        display: inline-block;
        /* margin-right: 2rem; *!/
        font-size: var(--fs-md);
        font-weight: 400;
    } */
    /* .range {
        font-size: var(--fs-sm);
        font-weight: 200;
        margin-right: 0.5rem;
    } */
    /* .item a {
        display: inline-block;
        padding: 0.5rem 1.5rem;
        background-color: var(--color-bg-btn);
        border-radius: 0.25rem;
        cursor: pointer;
        font-size: var(--fs-xs);
        transition: all 150ms ease-in-out;
    } */
    /* .item a:hover,
    .item:hover a {
        background-color: var(--color-bg-btn-hover);
        box-shadow: var(--button-shadow);
    } */
</style>