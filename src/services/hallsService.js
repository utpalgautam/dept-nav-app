import { db } from './firebaseConfig';
import {
    collection,
    getDocs,
    getDoc,
    doc,
    setDoc,
    updateDoc,
    deleteDoc,
    query,
    where,
    deleteField
} from 'firebase/firestore';

const HALLS_COLLECTION = 'halls';
const LOCATIONS_COLLECTION = 'locations';

/**
 * Helper to convert a map file to a compressed Base64 string for direct Firestore storage.
 * Scaled down to max 800px wide/tall to avoid exceeding Firestore's 1MB document limit.
 */
const fileToBase64 = (file) => {
    return new Promise((resolve, reject) => {
        if (!file) return resolve(null);
        const reader = new FileReader();
        reader.readAsDataURL(file);
        reader.onload = (e) => {
            const img = new Image();
            img.src = e.target.result;
            img.onload = () => {
                const canvas = document.createElement('canvas');
                const MAX_DIMENSION = 800;
                let { width, height } = img;

                if (width > height) {
                    if (width > MAX_DIMENSION) {
                        height *= MAX_DIMENSION / width;
                        width = MAX_DIMENSION;
                    }
                } else {
                    if (height > MAX_DIMENSION) {
                        width *= MAX_DIMENSION / height;
                        height = MAX_DIMENSION;
                    }
                }
                canvas.width = width;
                canvas.height = height;
                const ctx = canvas.getContext('2d');
                ctx.drawImage(img, 0, 0, width, height);

                resolve(canvas.toDataURL('image/jpeg', 0.8));
            };
            img.onerror = reject;
        };
        reader.onerror = reject;
    });
};

/**
 * Generates a sequential ID (e.g., H1, H2) for halls.
 */
async function generateNextId() {
    const snapshot = await getDocs(collection(db, HALLS_COLLECTION));
    let maxId = 0;
    snapshot.forEach(docSnap => {
        const idStr = docSnap.id;
        if (idStr.startsWith('H')) {
            const num = parseInt(idStr.substring(1), 10);
            if (!isNaN(num) && num > maxId) {
                maxId = num;
            }
        }
    });
    return `H${maxId + 1}`;
}

export async function fetchAllHalls() {
    try {
        const [hallsSnapshot, locationsSnapshot] = await Promise.all([
            getDocs(collection(db, HALLS_COLLECTION)),
            getDocs(query(collection(db, LOCATIONS_COLLECTION), where('type', '==', 'hall')))
        ]);

        const locationsMap = {};
        locationsSnapshot.forEach(docSnap => {
            locationsMap[docSnap.id] = { id: docSnap.id, ...docSnap.data() };
        });

        return hallsSnapshot.docs.map(docSnap => {
            const hallData = docSnap.data();
            const location = locationsMap[hallData.locationId] || {};
            
            return {
                id: docSnap.id,
                ...hallData,
                // Merge location fields into hall for UI compatibility
                building: location.buildingId || '',
                floor: location.floor !== undefined ? location.floor : '',
                roomNumber: location.roomNumber || '',
                category: 'HALL'
            };
        });
    } catch (err) {
        console.error('Error fetching halls:', err);
        throw err;
    }
}

export async function addHall(itemData) {
    try {
        if (!itemData.name) throw new Error('Name is required');

        // 1. Create Location document
        const locationRef = doc(collection(db, LOCATIONS_COLLECTION));
        const locationData = {
            name: itemData.name,
            type: 'hall',
            buildingId: itemData.building || '',
            floor: parseInt(itemData.floor) || 0,
            roomNumber: itemData.roomNumber || '',
            description: `Hall: ${itemData.name} - ${itemData.status}`,
            isActive: itemData.status === 'ACTIVE',
            tags: ['hall', itemData.name, itemData.building, itemData.department].filter(Boolean)
        };

        await setDoc(locationRef, locationData);

        // 2. Create Hall document (Strictly normalized)
        const finalItemData = {
            name: itemData.name,
            type: itemData.type,
            department: itemData.department || '',
            locationId: locationRef.id,
            contactPerson: itemData.contactPerson || null,
            status: itemData.status,
            createdAt: new Date().toISOString()
        };

        const nextId = await generateNextId();
        const docRef = doc(db, HALLS_COLLECTION, nextId);
        await setDoc(docRef, finalItemData);

        return { 
            id: nextId, 
            ...finalItemData,
            building: locationData.buildingId,
            floor: locationData.floor,
            roomNumber: locationData.roomNumber,
            category: 'HALL'
        };
    } catch (err) {
        console.error('Error adding hall:', err);
        throw err;
    }
}

export async function updateHall(id, itemData) {
    try {
        const docRef = doc(db, HALLS_COLLECTION, id);
        const snap = await getDoc(docRef);
        if (!snap.exists()) throw new Error('Hall not found');

        const existingData = snap.data();

        // 1. Update Hall (Clean structure)
        const hallUpdate = {
            name: itemData.name,
            type: itemData.type,
            department: itemData.department,
            contactPerson: itemData.contactPerson,
            status: itemData.status,
            updatedAt: new Date().toISOString(),
            // EXPLICITLY remove legacy fields
            building: deleteField(),
            floor: deleteField(),
            roomNumber: deleteField(),
            capacity: deleteField(),
            mapUrl: deleteField(),
            cabin: deleteField(),
            incharge: deleteField(),
            inchargeEmail: deleteField(),
            timing: deleteField()
        };

        // Filter out undefined values but KEEP deleteField()
        Object.keys(hallUpdate).forEach(key => {
            if (hallUpdate[key] === undefined) delete hallUpdate[key];
        });

        await updateDoc(docRef, hallUpdate);

        // 2. Update Location
        if (existingData.locationId) {
            const locRef = doc(db, LOCATIONS_COLLECTION, existingData.locationId);
            const locUpdate = {
                updatedAt: new Date().toISOString()
            };

            if (itemData.name !== undefined) locUpdate.name = itemData.name;
            if (itemData.building !== undefined) locUpdate.buildingId = itemData.building;
            if (itemData.floor !== undefined) locUpdate.floor = parseInt(itemData.floor) || 0;
            if (itemData.roomNumber !== undefined) locUpdate.roomNumber = itemData.roomNumber;
            
            if (itemData.status !== undefined || itemData.name !== undefined) {
                const currentStatus = itemData.status || existingData.status;
                const currentName = itemData.name || existingData.name;
                const currentBuilding = itemData.building || existingData.building || '';
                
                locUpdate.isActive = currentStatus === 'ACTIVE';
                locUpdate.description = `Hall: ${currentName} - ${currentStatus}`;
                locUpdate.tags = ['hall', currentName, currentBuilding, itemData.department || existingData.department].filter(Boolean);
            }

            await updateDoc(locRef, locUpdate);
        }
    } catch (err) {
        console.error('Error updating hall:', err);
        throw err;
    }
}

export async function deleteHall(id) {
    try {
        const docRef = doc(db, HALLS_COLLECTION, id);
        const snap = await getDoc(docRef);
        if (snap.exists()) {
            const data = snap.data();
            if (data.locationId) {
                await deleteDoc(doc(db, LOCATIONS_COLLECTION, data.locationId));
            }
            await deleteDoc(docRef);
        }
    } catch (err) {
        console.error('Error deleting hall:', err);
        throw err;
    }
}
