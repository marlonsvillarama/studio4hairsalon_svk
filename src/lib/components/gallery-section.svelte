<section>
    <div class="wrapper">
        <div class="carousel-track">
            <div class="carousel-item">Item 1</div>
            <div class="carousel-item">Item 2</div>
            <div class="carousel-item">Item 3</div>
            <div class="carousel-item">Item 4</div>
            <div class="carousel-item">Item 5</div>
            <div class="carousel-item">Item 1</div>
            <div class="carousel-item">Item 2</div>
            <div class="carousel-item">Item 3</div>
            <div class="carousel-item">Item 4</div>
            <div class="carousel-item">Item 5</div>
        </div>
    </div>
</section>

<style>
    .wrapper {
        overflow: hidden;
        width: 100%;
        background-color: var(--color-accent-50);
        white-space: nowrap;
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
        width: 200px;
        height: 100px;
        background-color: #3498db;
        color: white;
        display: flex;
        align-items: center;
        justify-content: center;
        font-weight: bold;
        border-radius: 0.5rem;
        /* flex-shrink: 0; */
        /* position: absolute; */
        /* top: 0; */
        /* left: 0; */
        height: 100%;
        /* transform: translate3d(0, 0, 0); */
        /* animation: scrollSlowly 60s linear infinite; */
    }

    @keyframes scrollSlowly {
        /* 0% { transform: translateX(0); } */
        100% { transform: translateX(-100%); }
    }

    /* @keyframes moveSlide */
</style>