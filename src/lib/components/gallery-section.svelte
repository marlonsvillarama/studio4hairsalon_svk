<script>
    import ActionButton from "./shared/action-button.svelte";
    let items = [
        '/images/gallery/avif/001.avif',
        '/images/gallery/avif/002.avif',
        '/images/gallery/avif/006.avif',
        '/images/gallery/avif/003.avif',
        '/images/gallery/avif/004.avif',
        '/images/gallery/avif/007.avif',
        '/images/gallery/avif/005.avif',
        '/images/gallery/avif/008.avif',
    ];
</script>

<section>
    <div class="wrapper">
        <div class="carousel-track">
            {#each [ ...items, ...items ] as item}
                <div class="carousel-item"
                    style="background-image: url({item})"></div>
            {/each}
        </div>
        <div class="actions">
            <ActionButton label="Read Our Reviews" link="/" />
        </div>
    </div>
</section>

<style>
    .wrapper {
        overflow: hidden;
        width: min(90%, 110rem);
        white-space: nowrap;
        position: relative;
        padding: 6rem 0 6rem;
    }
    .carousel-track {
        /* display: flex; */
        /* width: max-content; */
        /* animation: scrollSlowly 60s linear infinite; */
        /* margin: 0 auto; */
        /* position: relative; */
        /* overflow: hidden; */
        /* transform: translate3d(0, 0, 0); */
        display: flex;
        width: max-content;
        animation: scrollSlowly 60s linear infinite;
    }
    /* .carousel-group {
        display: flex;
        gap: 20px;
        padding-right: 20px;
    } */
    .carousel-item {
        width: 22rem;
        height: 25rem;
        /* background-color: #3498db; */
        color: white;
        margin-right: 0.5rem;
        background-size: cover;
        /* border: 1px solid var(--color-accent-400); */
        /* display: flex;
        align-items: center;
        justify-content: center;
        font-weight: bold;
        border-radius: 0.5rem; */
        /* flex-shrink: 0; */
        /* position: absolute; */
        /* top: 0; */
        /* left: 0; */
        /* height: 100%; */
        /* transform: translate3d(0, 0, 0); */
        /* animation: scrollSlowly 60s linear infinite; */
    }

    @keyframes scrollSlowly {
        0% { transform: translateX(0); }
        100% { transform: translateX(-50%); }
    }

    .actions {
        display: flex;
        align-items: center;
        justify-content: center;
        margin-top: 2rem;
    }
</style>