module.exports = {
    title: 'EKS GitOps hands-on',
    description: 'Progressive Delivery for Amazon EKS with App Mesh, FluxCD and Flagger',
    themeConfig: {
        displayAllHeaders: true,
        repo: 'weaveworks/eks-appmesh-profile',
        docsDir: 'docs',
        editLinks: false,
        editLinkText: 'Help us improve this page!',
        nav: [
            { text: 'Home', link: '/' },
        ],
        sidebar: [
            '/',
            '/intro/',
            '/prerequisites/',
            '/profile/',
            '/canary/',
            '/test/'
        ]
    },
    head: [
        ['link', { rel: 'icon', href: '/favicon.png' }],
        ['link', { rel: 'stylesheet', href: '/website.css' }]
    ]
};

