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

const FACULTY_COLLECTION = 'faculty';
const LOCATIONS_COLLECTION = 'locations';

/**
 * Helper to convert an image file to a compressed Base64 string for direct Firestore storage.
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

                // Compress as JPEG
                resolve(canvas.toDataURL('image/jpeg', 0.8));
            };
            img.onerror = reject;
        };
        reader.onerror = reject;
    });
};

/**
 * Generates a sequential ID (e.g., F1, F2) for the faculty.
 */
async function generateNextFacultyId() {
    const snapshot = await getDocs(collection(db, FACULTY_COLLECTION));
    let maxId = 0;
    snapshot.forEach(docSnap => {
        const idStr = docSnap.id;
        if (idStr.startsWith('F')) {
            const num = parseInt(idStr.substring(1), 10);
            if (!isNaN(num) && num > maxId) {
                maxId = num;
            }
        }
    });
    return `F${maxId + 1}`;
}

export async function fetchAllFaculty() {
    try {
        const [facultySnapshot, locationsSnapshot] = await Promise.all([
            getDocs(collection(db, FACULTY_COLLECTION)),
            getDocs(query(collection(db, LOCATIONS_COLLECTION), where('type', '==', 'faculty')))
        ]);

        const locationsMap = {};
        locationsSnapshot.forEach(docSnap => {
            locationsMap[docSnap.id] = docSnap.id; 
            // Better: store the whole data
            locationsMap[docSnap.id] = { id: docSnap.id, ...docSnap.data() };
        });

        return facultySnapshot.docs.map(docSnap => {
            const facultyData = docSnap.data();
            const location = locationsMap[facultyData.locationId] || {};
            
            return {
                id: docSnap.id,
                ...facultyData,
                // Merge location fields into faculty for UI compatibility
                // STRICTLY use location doc, as requested. 
                // Non-migrated docs will show empty until updated.
                building: location.buildingId || '',
                floor: location.floor !== undefined ? location.floor : '',
                cabin: location.roomNumber || ''
            };
        });
    } catch (err) {
        console.error('Error fetching faculty:', err);
        throw err;
    }
}

export async function addFaculty(facultyData) {
    try {
        // 1. Validate required fields
        if (!facultyData.name) throw new Error('Faculty name is required');
        
        // 2. We need to create a Location model first
        const locationRef = doc(collection(db, LOCATIONS_COLLECTION));
        const locationData = {
            name: facultyData.name, 
            type: 'faculty',
            description: `Faculty: ${facultyData.role || ''} - Cabin ${facultyData.cabin || ''}`,
            roomNumber: facultyData.cabin || '',
            floor: facultyData.floor ? parseInt(facultyData.floor) || 0 : 0, 
            buildingId: facultyData.building || '', 
            isActive: true,
            tags: ['faculty', facultyData.role, facultyData.name].filter(Boolean)
        };

        await setDoc(locationRef, locationData);

        // 3. Process Profile Picture Base64
        let imageUrl = facultyData.imageUrl || null;
        if (facultyData.imageFile) {
            imageUrl = await fileToBase64(facultyData.imageFile);
        }

        // 4. Create the faculty document (NO building, floor, cabin here)
        const finalFacultyData = {
            name: facultyData.name,
            email: facultyData.email || '',
            role: facultyData.role || '',
            department: facultyData.department || '',
            imageUrl: imageUrl,
            locationId: locationRef.id, 
            createdAt: new Date().toISOString()
        };

        const nextFacultyId = await generateNextFacultyId();
        const docRef = doc(db, FACULTY_COLLECTION, nextFacultyId);
        await setDoc(docRef, finalFacultyData);

        return { 
            id: nextFacultyId, 
            ...finalFacultyData,
            // Add location details for immediate UI updates
            building: locationData.buildingId,
            floor: locationData.floor,
            cabin: locationData.roomNumber
        };
    } catch (err) {
        console.error('Error adding faculty:', err);
        throw err;
    }
}

export async function updateFaculty(facultyId, facultyData) {
    try {
        const docRef = doc(db, FACULTY_COLLECTION, facultyId);
        const snap = await getDoc(docRef);
        if (!snap.exists()) throw new Error('Faculty not found');

        const existingData = snap.data();

        // 1. Separate Faculty specific fields from Location fields
        const facultyUpdate = {
            name: facultyData.name,
            email: facultyData.email,
            role: facultyData.role,
            department: facultyData.department,
            updatedAt: new Date().toISOString(),
            // EXPLICITLY remove old fields from the document
            building: deleteField(),
            floor: deleteField(),
            cabin: deleteField()
        };

        // Handle Image
        if (facultyData.imageFile) {
            facultyUpdate.imageUrl = await fileToBase64(facultyData.imageFile);
        } else if (facultyData.imageUrl !== undefined) {
            facultyUpdate.imageUrl = facultyData.imageUrl;
        }

        // Explicitly remove keys we don't want in Faculty doc
        Object.keys(facultyUpdate).forEach(key => {
            if (facultyUpdate[key] === undefined) delete facultyUpdate[key];
        });

        await updateDoc(docRef, facultyUpdate);

        // 2. Update Location document
        if (existingData.locationId) {
            const locRef = doc(db, LOCATIONS_COLLECTION, existingData.locationId);
            const locUpdate = {
                updatedAt: new Date().toISOString()
            };

            if (facultyData.name !== undefined) locUpdate.name = facultyData.name;
            if (facultyData.cabin !== undefined) locUpdate.roomNumber = facultyData.cabin;
            if (facultyData.building !== undefined) locUpdate.buildingId = facultyData.building;
            if (facultyData.floor !== undefined) locUpdate.floor = parseInt(facultyData.floor) || 0;
            
            // Sync description and tags
            const currentRole = facultyData.role || existingData.role;
            const currentName = facultyData.name || existingData.name;
            const currentCabin = facultyData.cabin || existingData.cabin;
            
            locUpdate.description = `Faculty: ${currentRole} - Cabin ${currentCabin}`;
            locUpdate.tags = ['faculty', currentRole, currentName].filter(Boolean);

            await updateDoc(locRef, locUpdate);
        }
    } catch (err) {
        console.error('Error updating faculty:', err);
        throw err;
    }
}

export async function deleteFaculty(facultyId) {
    try {
        const docRef = doc(db, FACULTY_COLLECTION, facultyId);
        const snap = await getDoc(docRef);
        if (snap.exists()) {
            const data = snap.data();
            // Delete associated location if it exists
            if (data.locationId) {
                try {
                    await deleteDoc(doc(db, LOCATIONS_COLLECTION, data.locationId));
                } catch (e) {
                    console.error('Failed to delete associated location for faculty', e);
                }
            }
            await deleteDoc(docRef);
        }
    } catch (err) {
        console.error('Error deleting faculty:', err);
        throw err;
    }
}
