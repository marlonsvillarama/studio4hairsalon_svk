<script>
    import { cn } from '$lib/utils';
    
    let {
        label = 'Link',
        link = '/'
    } = $props();
</script>

<a href={link}
    class={cn(
        "tracking-[0.5px] py-[0.5rem] text-white font-normal border-b-2 border-b-transparent transition-[100ms] ease-in-out",
        "hover:border-b-accent hover:transform-[translateY(0px)]"
    )}
>{label}</a>
