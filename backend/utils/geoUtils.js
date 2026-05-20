/**
 * Geolocation Utilities
 * Pure math Haversine distance calculation for service zone checking.
 * No external dependencies required.
 */

const EARTH_RADIUS_KM = 6371;

/**
 * Calculate the Haversine distance between two GPS coordinates.
 * @param {number} lat1 - Latitude of point 1 (degrees)
 * @param {number} lng1 - Longitude of point 1 (degrees)
 * @param {number} lat2 - Latitude of point 2 (degrees)
 * @param {number} lng2 - Longitude of point 2 (degrees)
 * @returns {number} Distance in kilometers
 */
function haversineDistance(lat1, lng1, lat2, lng2) {
    const toRad = (deg) => (deg * Math.PI) / 180;

    const dLat = toRad(lat2 - lat1);
    const dLng = toRad(lng2 - lng1);

    const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
        Math.sin(dLng / 2) * Math.sin(dLng / 2);

    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return EARTH_RADIUS_KM * c;
}

/**
 * Check if a point (lat, lng) falls inside any of the defined service zones.
 * @param {number} lat - Latitude of the point to check
 * @param {number} lng - Longitude of the point to check
 * @param {Array} zones - Array of zone objects: [{name, lat, lng, radiusKm}]
 * @returns {{ active: boolean, nearestZone: {name: string, distance: number} | null }}
 */
function isPointInAnyZone(lat, lng, zones) {
    if (!zones || !Array.isArray(zones) || zones.length === 0) {
        // No zones configured = all locations are active
        return { active: true, nearestZone: null };
    }

    let nearestZone = null;
    let nearestDistance = Infinity;

    for (const zone of zones) {
        const zoneLat = parseFloat(zone.lat);
        const zoneLng = parseFloat(zone.lng);
        const radiusKm = parseFloat(zone.radiusKm) || 15;

        if (isNaN(zoneLat) || isNaN(zoneLng)) continue;

        const distance = haversineDistance(lat, lng, zoneLat, zoneLng);

        if (distance < nearestDistance) {
            nearestDistance = distance;
            nearestZone = { name: zone.name || 'Unknown', distance: Math.round(distance * 100) / 100 };
        }

        if (distance <= radiusKm) {
            return {
                active: true,
                nearestZone: { name: zone.name || 'Unknown', distance: Math.round(distance * 100) / 100 }
            };
        }
    }

    return { active: false, nearestZone };
}

module.exports = { haversineDistance, isPointInAnyZone };
