return {
    -- Connection (set the key in secrets.cfg with: set fivemesh_api_key "...")
    apiKey = GetConvar('fivemesh_api_key', ''), -- FiveMesh API key; empty turns logging and uploads off
    apiUrl = 'https://api.fivemesh.io/v1', -- FiveMesh API base URL
    logsUrl = 'https://logs.fivemesh.io/v1', -- FiveMesh log ingest URL

    -- Requests
    timeout = 15000, -- milliseconds before a request is abandoned
    maxAttempts = 5, -- tries per request before giving up
    maxBackoff = 30000, -- longest wait between retries, in milliseconds

    -- Log batching
    logs = {
        flushInterval = 5000, -- milliseconds between sends of queued logs
        batchSize = 100, -- most logs sent in one request
        maxBatchBytes = 900 * 1024, -- most bytes in one request
        maxEventBytes = 16 * 1024, -- logs larger than this many bytes are trimmed
        maxQueued = 5000, -- most logs held while FiveMesh can't be reached; older ones drop first
    },

    -- Phone camera uploads from npwd
    phone = {
        folder = 'uploads/phone', -- FiveMesh storage folder for photos
        maxBytes = 5 * 1024 * 1024, -- largest photo accepted, in bytes
    },
}
