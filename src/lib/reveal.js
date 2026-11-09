// @ts-nocheck
export function reveal(node, options = {}) {
    const { threshold = 0.15, once = true } = options;

    const observer = new IntersectionObserver(entries => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                node.classList.add('reveal-visible');
                if (once) {
                    observer.unobserve(node);
                }
            }
            else if (!once) {
                node.classList.remove('reveal-visible');
            }
        });
    }, { threshold });

    observer.observe(node);

    return {
        destroy() {
            observer.disconnect();
        }
    }
}
