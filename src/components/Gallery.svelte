<script>
    import Masonry from "./Masonry.svelte";
    // import { createGalleryData } from "$lib/data/gallery.svelte";
    // const gallery = createGalleryData();

    /* const randomizeImages = () => {
        const MAX_COLUMNS = 3;
        let output = [];
        let indexes = [];
        let count = gallery.images.length;
        let imagesPerColumn = Math.ceil(count / MAX_COLUMNS);
        console.log(`count = ${count}; imagesPerColumn = ${imagesPerColumn}`);

        let column = [];
        while (indexes.length < count) {
            let rand = Math.floor(
                Math.random() * (
                    Math.floor(gallery.images.length) - Math.ceil(1) + 1
                )
            );
            if (indexes.indexOf(rand) >= 0) { continue; }

            indexes.push(rand);
            column.push(gallery.images[rand]);
            console.log('indexes', indexes);

            if (column.length >= imagesPerColumn || indexes.length >= count) {
                console.log('column indexes', column);
                output.push([ ...column ]);
                column = [];
                imagesPerColumn = Math.ceil((count - indexes.length) / (MAX_COLUMNS - output.length));
            }
        }
        
        console.log('END', output);
        return output;
    };

    let images = randomizeImages(); */
    let { images } = $props();
    
    const groupImages = () => {
        let output = [];
        // let images = gallery.images;
        let MAX_COLUMNS = 3;
        let imagesPerColumn = Math.ceil(images.length / MAX_COLUMNS);
        
        let start = 0;
        let end = imagesPerColumn;
        for (let i = 0; i < MAX_COLUMNS; i++) {
            output.push(images.slice(start, end));

            start = end;
            let remaining = images.length - end;
            imagesPerColumn = remaining / (MAX_COLUMNS - (i + 1));
            end += imagesPerColumn;
            console.log(`start = ${start}; end = ${end}; imagesPerColumn = ${imagesPerColumn}`);
        }

        console.log('output', output);
        return output;
    };
</script>

<section class="wrapper">
    <div class="grid">
        <!-- <Masonry
            stretchFirst={true}
            gridGap={'1.5rem'}
            colWidth={'minmax(Min(20rem, 100%), 1fr'}
            items={images}
        >
            {#each images as img}
                <img src={img} alt="" loading="lazy">
            {/each}
        </Masonry> -->
        {#each groupImages() as column}
            <div class="col">
                {#each column as img}
                    <img src={img} alt="" loading="lazy">
                {/each}
            </div>
        {/each}
        <!-- <div class="col">
            <img src="/src/lib/images/fb/haircut-001.jpg" alt="" class="img" loading="lazy">
            <img src="/src/lib/images/fb/haircut-001.jpg" alt="" class="img" loading="lazy">
            <img src="/src/lib/images/fb/haircut-001.jpg" alt="" class="img" loading="lazy">
        </div> -->
    </div>
</section>

<style>
    .grid {
        display: flex;
        flex-direction: column;
        /* display: grid;
        grid-template-columns: 1fr; */
        gap: 1rem;
        width: 100%;
    }
    @media (min-width: 32rem) {
        .grid {
            display: grid;
            grid-template-columns: repeat(3, 1fr);
            /* grid-auto-rows: minmax(20rem, auto); */
        }
    }
    .col {
        /* border: 1px solid red; */
        display: flex;
        flex-direction: column;
        gap: 1rem;
        /* width: 100%; */
        justify-content: flex-start;
    }
    img {
        max-inline-size: 100%;
        block-size: auto;
        object-fit: contain;
        object-position: center center;
        /* width: 100%;
        height: auto; */
    }
</style>