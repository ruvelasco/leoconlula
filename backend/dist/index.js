import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import dotenv from 'dotenv';
import multer from 'multer';
import path from 'path';
import { fileURLToPath } from 'url';
import fs from 'fs';
import prisma from './config/database.js';
import authRoutes from './routes/auth.routes.js';
import estudianteRoutes from './routes/estudiante.routes.js';
import { authenticate } from './middleware/auth.js';
console.log('🚀 Starting LeoConLula Backend...');
dotenv.config();
console.log('✅ Environment loaded');
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
console.log('📦 Initializing Express...');
const app = express();
console.log('✅ Express initialized');
// Configurar multer para almacenamiento de archivos
const uploadsDir = path.join(__dirname, '../uploads');
const avatarsDir = path.join(uploadsDir, 'avatars');
const vocabularioDir = path.join(uploadsDir, 'vocabulario');
// Crear directorios si no existen
[uploadsDir, avatarsDir, vocabularioDir].forEach(dir => {
    if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
    }
});
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        const type = req.query.type || 'avatar';
        const dest = type === 'vocabulario' ? vocabularioDir : avatarsDir;
        cb(null, dest);
    },
    filename: (req, file, cb) => {
        const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
        cb(null, uniqueSuffix + path.extname(file.originalname));
    }
});
const upload = multer({
    storage,
    limits: { fileSize: 5 * 1024 * 1024 }, // 5MB max
    fileFilter: (req, file, cb) => {
        const allowedTypes = /jpeg|jpg|png|gif/;
        const extname = allowedTypes.test(path.extname(file.originalname).toLowerCase());
        const mimetype = allowedTypes.test(file.mimetype);
        if (mimetype && extname) {
            return cb(null, true);
        }
        cb(new Error('Solo se permiten imágenes (jpeg, jpg, png, gif)'));
    }
});
// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(morgan('combined'));
app.use('/uploads', express.static(uploadsDir));
const PORT = process.env.PORT ? Number(process.env.PORT) : 8080;
// Health check
app.get('/health', (_req, res) => {
    res.json({ status: 'ok', message: 'LeoConLula API is running' });
});
// ==================== AUTHENTICATION ROUTES ====================
app.use('/auth', authRoutes);
// ==================== PROTECTED ROUTES ====================
app.use('/api/estudiantes', estudianteRoutes);
// ==================== VOCABULARIO ROUTES ====================
// Vocabulario endpoints (protected)
app.post('/api/vocabulario', authenticate, async (req, res) => {
    try {
        const item = await prisma.vocabulario.create({ data: req.body });
        res.status(201).json(item);
    }
    catch (err) {
        res.status(400).json({ error: err.message });
    }
});
app.get('/api/vocabulario', authenticate, async (req, res) => {
    try {
        const estudianteId = req.query.estudianteId ? Number(req.query.estudianteId) : undefined;
        if (!req.user) {
            res.status(401).json({ error: 'No autenticado' });
            return;
        }
        // Verify student is assigned to current user
        if (estudianteId) {
            const asignacion = await prisma.estudianteAsignacion.findFirst({
                where: {
                    authUserId: req.user.userId,
                    estudianteId,
                },
            });
            if (!asignacion) {
                res.status(403).json({ error: 'Acceso denegado a este estudiante' });
                return;
            }
        }
        const items = await prisma.vocabulario.findMany({
            where: { estudianteId }
        });
        res.json(items);
    }
    catch (err) {
        res.status(400).json({ error: err.message });
    }
});
app.delete('/api/vocabulario/:id', authenticate, async (req, res) => {
    try {
        const id = Number(req.params.id);
        // Verify ownership
        const item = await prisma.vocabulario.findUnique({ where: { id } });
        if (!item || !item.estudianteId) {
            res.status(404).json({ error: 'Vocabulario no encontrado' });
            return;
        }
        const asignacion = await prisma.estudianteAsignacion.findFirst({
            where: {
                authUserId: req.user.userId,
                estudianteId: item.estudianteId,
            },
        });
        if (!asignacion) {
            res.status(403).json({ error: 'Acceso denegado' });
            return;
        }
        await prisma.sesionVocabulario.deleteMany({ where: { vocabularioId: id } });
        await prisma.vocabulario.delete({ where: { id } });
        res.status(204).send();
    }
    catch (err) {
        res.status(400).json({ error: err.message });
    }
});
// ==================== SESIONES ROUTES ====================
// Sesiones endpoints (protected)
app.post('/api/sesiones', authenticate, async (req, res) => {
    try {
        const { estudianteId, actividad, inicio_at, nivel, palabras = [] } = req.body;
        // Verify student is assigned to current user
        const asignacion = await prisma.estudianteAsignacion.findFirst({
            where: {
                authUserId: req.user.userId,
                estudianteId,
            },
        });
        if (!asignacion) {
            res.status(403).json({ error: 'Acceso denegado a este estudiante' });
            return;
        }
        const inicio = inicio_at ?? Date.now();
        const data = {
            estudianteId,
            actividad,
            inicio_at: BigInt(inicio),
            nivel,
            palabra1: palabras[0],
            palabra2: palabras[1],
            palabra3: palabras[2],
        };
        const sesion = await prisma.actividadSesion.create({ data });
        res.status(201).json(sesion);
    }
    catch (err) {
        res.status(400).json({ error: err.message });
    }
});
app.patch('/api/sesiones/:id/finalizar', authenticate, async (req, res) => {
    try {
        const id = Number(req.params.id);
        const { fin_at, aciertos, errores, resultado, duracion_ms } = req.body;
        // Verify ownership
        const sesion = await prisma.actividadSesion.findUnique({ where: { id } });
        if (!sesion) {
            res.status(404).json({ error: 'Sesión no encontrada' });
            return;
        }
        const asignacion = await prisma.estudianteAsignacion.findFirst({
            where: {
                authUserId: req.user.userId,
                estudianteId: sesion.estudianteId,
            },
        });
        if (!asignacion) {
            res.status(403).json({ error: 'Acceso denegado' });
            return;
        }
        let duracion = duracion_ms;
        let finValue;
        if (fin_at != null) {
            finValue = BigInt(fin_at);
            if (duracion == null && sesion.inicio_at) {
                duracion = Number(finValue - sesion.inicio_at);
            }
        }
        const updated = await prisma.actividadSesion.update({
            where: { id },
            data: {
                fin_at: finValue,
                duracion_ms: duracion,
                aciertos,
                errores,
                resultado,
            },
        });
        res.json(updated);
    }
    catch (err) {
        res.status(400).json({ error: err.message });
    }
});
app.post('/api/sesiones/:id/detalle', authenticate, async (req, res) => {
    try {
        const sesionId = Number(req.params.id);
        const { vocabularioId, mostrada = false, acierto = false, tiempo_ms } = req.body;
        const detalle = await prisma.sesionVocabulario.create({
            data: {
                sesionId,
                vocabularioId,
                mostrada,
                acierto,
                tiempo_ms,
            },
        });
        res.status(201).json(detalle);
    }
    catch (err) {
        res.status(400).json({ error: err.message });
    }
});
app.delete('/api/sesiones/:id', authenticate, async (req, res) => {
    try {
        const id = Number(req.params.id);
        await prisma.sesionVocabulario.deleteMany({ where: { sesionId: id } });
        await prisma.actividadSesion.delete({ where: { id } });
        res.status(204).send();
    }
    catch (err) {
        res.status(400).json({ error: err.message });
    }
});
app.delete('/api/sesiones', authenticate, async (req, res) => {
    try {
        const estudianteId = req.query.estudianteId ? Number(req.query.estudianteId) : undefined;
        if (estudianteId) {
            // Verify student is assigned to current user
            const asignacion = await prisma.estudianteAsignacion.findFirst({
                where: {
                    authUserId: req.user.userId,
                    estudianteId,
                },
            });
            if (!asignacion) {
                res.status(403).json({ error: 'Acceso denegado a este estudiante' });
                return;
            }
        }
        await prisma.sesionVocabulario.deleteMany({
            where: { sesion: estudianteId ? { estudianteId } : undefined }
        });
        await prisma.actividadSesion.deleteMany({
            where: estudianteId ? { estudianteId } : {}
        });
        res.status(204).send();
    }
    catch (err) {
        res.status(400).json({ error: err.message });
    }
});
app.get('/api/sesiones', authenticate, async (req, res) => {
    try {
        const { estudianteId, actividad } = req.query;
        const where = {};
        if (estudianteId) {
            const id = Number(estudianteId);
            // Verify student is assigned to current user
            const asignacion = await prisma.estudianteAsignacion.findFirst({
                where: {
                    authUserId: req.user.userId,
                    estudianteId: id,
                },
            });
            if (!asignacion) {
                res.status(403).json({ error: 'Acceso denegado a este estudiante' });
                return;
            }
            where.estudianteId = id;
        }
        if (actividad)
            where.actividad = actividad;
        const sesiones = await prisma.actividadSesion.findMany({
            where,
            include: {
                detalles: true,
                estudiante: {
                    select: {
                        id: true,
                        nombre: true
                    }
                }
            },
            orderBy: {
                inicio_at: 'desc'
            }
        });
        res.json(sesiones);
    }
    catch (err) {
        res.status(400).json({ error: err.message });
    }
});
// ==================== UPLOAD ROUTE ====================
app.post('/upload', authenticate, upload.single('file'), (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: 'No se subió ningún archivo' });
        }
        const type = req.query.type || 'avatar';
        const baseUrl = process.env.BASE_URL || `http://localhost:${PORT}`;
        const fileUrl = `${baseUrl}/uploads/${type === 'vocabulario' ? 'vocabulario' : 'avatars'}/${req.file.filename}`;
        res.json({
            filename: req.file.filename,
            url: fileUrl,
            size: req.file.size,
            mimetype: req.file.mimetype
        });
    }
    catch (err) {
        res.status(500).json({ error: err.message });
    }
});
// ==================== LEGACY COMPATIBILITY ROUTES ====================
// These routes maintain backward compatibility with the Flutter app until it's updated
// They map old endpoints to new ones
// OLD: GET /usuarios -> NEW: GET /api/estudiantes
app.get('/usuarios', authenticate, async (req, res) => {
    try {
        const asignaciones = await prisma.estudianteAsignacion.findMany({
            where: { authUserId: req.user.userId },
            include: { estudiante: true },
        });
        const estudiantes = asignaciones.map(a => a.estudiante);
        res.json(estudiantes);
    }
    catch (err) {
        res.status(400).json({ error: err.message });
    }
});
// OLD: POST /usuarios -> NEW: POST /api/estudiantes
app.post('/usuarios', authenticate, async (req, res) => {
    try {
        const estudiante = await prisma.estudiante.create({ data: req.body });
        await prisma.estudianteAsignacion.create({
            data: {
                authUserId: req.user.userId,
                estudianteId: estudiante.id,
                role: 'TUTOR',
                createdBy: req.user.userId,
            },
        });
        res.status(201).json(estudiante);
    }
    catch (err) {
        res.status(400).json({ error: err.message });
    }
});
// OLD: /vocabulario -> NEW: /api/vocabulario (with userId -> estudianteId mapping)
app.get('/vocabulario', authenticate, async (req, res) => {
    try {
        // Support both userId (legacy) and estudianteId (new)
        const estudianteId = req.query.estudianteId
            ? Number(req.query.estudianteId)
            : req.query.userId
                ? Number(req.query.userId)
                : undefined;
        if (estudianteId) {
            const asignacion = await prisma.estudianteAsignacion.findFirst({
                where: {
                    authUserId: req.user.userId,
                    estudianteId,
                },
            });
            if (!asignacion) {
                res.status(403).json({ error: 'Acceso denegado a este estudiante' });
                return;
            }
        }
        const items = await prisma.vocabulario.findMany({ where: { estudianteId } });
        // Add idUsuario for compatibility with Flutter SQLite
        const itemsCompat = items.map((item) => ({
            ...item,
            idUsuario: item.estudianteId,
            usuarioId: item.estudianteId, // For backward compatibility
        }));
        res.json(itemsCompat);
    }
    catch (err) {
        res.status(400).json({ error: err.message });
    }
});
// 404 handler
app.use((_req, res) => {
    res.status(404).json({ error: 'Not found' });
});
// Start server
app.listen(PORT, '0.0.0.0', () => {
    console.log(`✅ API listening on port ${PORT}`);
    console.log(`📍 Base URL: http://localhost:${PORT}`);
    console.log(`🔐 Authentication: /auth/login, /auth/register`);
    console.log(`👨‍🎓 Estudiantes: /api/estudiantes`);
    console.log(`📚 Vocabulario: /api/vocabulario`);
    console.log(`📊 Sesiones: /api/sesiones`);
});
