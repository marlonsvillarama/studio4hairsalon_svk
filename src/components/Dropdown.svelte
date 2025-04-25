<script>
    import { onMount } from "svelte";

    let { id } = $props();

    onMount(() => {
        let container = document.getElementById(id);
        let selectButton = container?.querySelector('.select-button');
        let dropDown = container?.querySelector('.select-options');

        const toggleDropdown = () => {
            const isOpen = dropDown?.classList.contains('hidden') === false;
            dropDown?.classList.toggle('hidden');
        };
        selectButton?.addEventListener('click', () => { toggleDropdown(); });

        const options = dropDown?.querySelectorAll('li');
        const selectedValue = selectButton?.querySelector('.selected-value');

        const handleOptionSelect = (option) => {
            options?.forEach(opt => opt.classList.remove('selected'));
            option.classList.add('selected');

            if (selectedValue) {
                selectedValue.textContent = option.textContent.trim();
            }
        };
        options?.forEach(option => {
            option.addEventListener('click', () => {
                handleOptionSelect(option);
                toggleDropdown();
            });
        });
    });
</script>

<div class="select" {id}>
    <button class="select-button">
        <span class="selected-value">Choose the service you want...</span>
        <span class="arrow"></span>
    </button>
    <ul class="select-options hidden">
        <li class="reminder" value="">Please select a service...</li>
        <li value="1">Option 1</li>
        <li value="2">Option 2</li>
    </ul>
</div>

<style>
    .select {
        position: relative;
        display: inline-block;
        width: 100%;
    }
    .select-button {
        display: flex;
        justify-content: space-between;
        align-items: center;
        background-color: white;
        border: 1px solid var(--color-accent);
        border-radius: 0.5rem;
        cursor: pointer;
        font-size: var(--fs-sm);
        padding: 0.75rem 1.25rem;
        width: 100%;
    }
    .selected-value {
        color: var(--color-grey-dark-03-rgb);
    }
    .arrow {
        border-left: 0.5rem solid transparent;
        border-right: 0.5rem solid transparent;
        border-top: 0.5rem solid var(--color-grey-dark-03-rgb);
        transition: transform ease-in-out 300ms;
    }
    ul {
        position: absolute;
        top: 100%;
        left: 0;
        width: 100%;
        border: 1px solid var(--color-accent);
        border-radius: 0.5rem;
        background-color: white;
        list-style: none;
        padding: 0.75rem 1.25rem;
        margin: 0.5rem 0 0;
        box-shadow: var(--button-shadow);
        max-height: 15rem;
        overflow-y: auto;
    }
    ul::-webkit-scrollbar {
        width: 0.5rem;
    }
    ul::-webkit-scrollbar-track {
        background-color: #f1f1f1;
        border-radius: 0.5rem;
    }
    ul::-webkit-scrollbar-thumb {
        background-color: var(--color-grey-dark-03-rgb);
        border-radius: 0.5rem;
    }
    li {
        padding: 0.5rem 1rem;
        cursor: pointer;
        color: var(--color-grey-dark-03-rgb);
        font-family: var(--font-default);
        font-size: var(--fs-sm);
        font-weight: 300;
        transition: all 150ms ease-in-out;
        border-radius: 0.25rem;
    }
    li.reminder {
        font-style: italic;
    }
    li.selected {
        background-color: var(--color-accent);
        font-weight: 600;
    }
    li:hover:not(.reminder),
    li:focus {
        background-color: #f2f2f2;
        font-weight: 400;
    }
</style>