/**
 * CloudFront Function for Single Page Application (SPA) Routing
 * 
 * This function handles client-side routing for the React/Vue SPA by:
 * 1. Serving static assets directly (JS, CSS, images)
 * 2. Redirecting all other requests to index.html for client-side routing
 * 3. Handling the callback route for OAuth authentication
 */

function handler(event) {
    var request = event.request;
    var uri = request.uri;
    
    // Log the request for debugging
    console.log('Processing request for URI:', uri);
    
    // Handle root path
    if (uri === '/') {
        request.uri = '/index.html';
        return request;
    }
    
    // Handle static assets - serve them directly
    if (uri.match(/\.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot|map)$/)) {
        return request;
    }
    
    // Handle specific files that should be served directly
    if (uri.match(/\.(html|json|xml|txt|pdf)$/)) {
        return request;
    }
    
    // Handle OAuth callback route
    if (uri.startsWith('/callback')) {
        request.uri = '/index.html';
        return request;
    }
    
    // Handle logout route
    if (uri.startsWith('/logout')) {
        request.uri = '/index.html';
        return request;
    }
    
    // Handle API health check (should be handled by API Gateway, but just in case)
    if (uri.startsWith('/health')) {
        // Let this pass through to origin (though it should go to API Gateway)
        return request;
    }
    
    // For all other routes (SPA client-side routes), serve index.html
    // This allows the client-side router to handle the routing
    if (!uri.includes('.')) {
        request.uri = '/index.html';
        return request;
    }
    
    // Default: serve the request as-is
    return request;
}