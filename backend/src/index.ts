import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import { PrismaClient } from '@prisma/client';
import dotenv from 'dotenv';
import multer from 'multer';
import path from 'path';
import { fileURLToPath } from 'url';
import fs from 'fs';

console.log('🚀 Starting LeoConLula Backend...');
dotenv.config();
console.log('✅ Environment loaded');

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

console.log('📦 Initializing Express and Prisma...');
const app = express();
const prisma = new PrismaClient();
console.log('✅ Express and Prisma initialized');

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
    const type = req.query.type as string || 'avatar';
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

app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));
app.use(morgan('combined'));
app.use('/uploads', express.static(uploadsDir));

const PORT = process.env.PORT ? Number(process.env.PORT) : 8080;

app.get('/health', (_req, res) => {
  res.json({ status: 'ok' });
});

// Usuarios
app.post('/usuarios', async (req, res) => {
  try {
    const user = await prisma.usuario.create({ data: req.body });
    res.status(201).json(user);
  } catch (err) {
    res.status(400).json({ error: (err as Error).message });
  }
});

app.get('/usuarios', async (_req, res) => {
  const users = await prisma.usuario.findMany();
  res.json(users);
});

app.delete('/usuarios/:id', async (req, res) => {
  const id = Number(req.params.id);
  try {
    await prisma.sesionVocabulario.deleteMany({ where: { sesion: { userId: id } } });
    await prisma.actividadSesion.deleteMany({ where: { userId: id } });
    await prisma.vocabulario.deleteMany({ where: { usuarioId: id } });
    await prisma.usuario.delete({ where: { id } });
    res.status(204).send();
  } catch (err) {
    res.status(400).json({ error: (err as Error).message });
  }
});

app.patch('/usuarios/:id/campos', async (req, res) => {
  const id = Number(req.params.id);
  try {
    const user = await prisma.usuario.update({ where: { id }, data: req.body });
    res.json(user);
  } catch (err) {
    res.status(400).json({ error: (err as Error).message });
  }
});

app.get('/usuarios/:id/orden-actividades', async (req, res) => {
  const id = Number(req.params.id);
  try {
    const user = await prisma.usuario.findUnique({
      where: { id },
      select: { orden_actividades: true }
    });
    const orden = user?.orden_actividades?.split(',') || [
      'aprendizaje',
      'discriminacion',
      'discriminacion_inversa',
      'silabas',
      'arrastre',
      'doble',
      'silabas_orden',
      'silabas_distrac'
    ];
    res.json(orden);
  } catch (err) {
    res.status(400).json({ error: (err as Error).message });
  }
});

app.patch('/usuarios/:id/orden-actividades', async (req, res) => {
  const id = Number(req.params.id);
  const { orden } = req.body; // Array de strings
  try {
    const user = await prisma.usuario.update({
      where: { id },
      data: { orden_actividades: orden.join(',') }
    });
    res.json(user);
  } catch (err) {
    res.status(400).json({ error: (err as Error).message });
  }
});

app.get('/usuarios/:id/actividades-habilitadas', async (req, res) => {
  const id = Number(req.params.id);
  try {
    const user = await prisma.usuario.findUnique({
      where: { id },
      select: { actividades_habilitadas: true }
    });
    const habilitadas = user?.actividades_habilitadas?.split(',') || [
      'aprendizaje',
      'discriminacion',
      'discriminacion_inversa',
      'silabas',
      'arrastre',
      'doble',
      'silabas_orden',
      'silabas_distrac'
    ];
    res.json(habilitadas);
  } catch (err) {
    res.status(400).json({ error: (err as Error).message });
  }
});

app.patch('/usuarios/:id/actividades-habilitadas', async (req, res) => {
  const id = Number(req.params.id);
  const { actividades } = req.body; // Array de strings
  try {
    const user = await prisma.usuario.update({
      where: { id },
      data: { actividades_habilitadas: actividades.join(',') }
    });
    res.json(user);
  } catch (err) {
    res.status(400).json({ error: (err as Error).message });
  }
});

// Vocabulario
app.post('/vocabulario', async (req, res) => {
  try {
    const item = await prisma.vocabulario.create({ data: req.body });
    res.status(201).json(item);
  } catch (err) {
    res.status(400).json({ error: (err as Error).message });
  }
});

app.get('/vocabulario', async (req, res) => {
  const userId = req.query.userId ? Number(req.query.userId) : undefined;
  const items = await prisma.vocabulario.findMany({ where: { usuarioId: userId } });
  res.json(items);
});

app.delete('/vocabulario/:id', async (req, res) => {
  const id = Number(req.params.id);
  try {
    await prisma.sesionVocabulario.deleteMany({ where: { vocabularioId: id } });
    await prisma.vocabulario.delete({ where: { id } });
    res.status(204).send();
  } catch (err) {
    res.status(400).json({ error: (err as Error).message });
  }
});

// Sesiones
app.post('/sesiones', async (req, res) => {
  try {
    const { userId, actividad, inicio_at, nivel, palabras = [] } = req.body;
    const inicio = inicio_at ?? Date.now();
    const data: any = {
      userId,
      actividad,
      inicio_at: BigInt(inicio),
      nivel,
      palabra1: palabras[0],
      palabra2: palabras[1],
      palabra3: palabras[2],
    };
    const sesion = await prisma.actividadSesion.create({ data });
    res.status(201).json(sesion);
  } catch (err) {
    res.status(400).json({ error: (err as Error).message });
  }
});

app.patch('/sesiones/:id/finalizar', async (req, res) => {
  const id = Number(req.params.id);
  const { fin_at, aciertos, errores, resultado, duracion_ms } = req.body;
  try {
    let duracion = duracion_ms;
    let finValue: bigint | undefined;
    if (fin_at != null) {
      finValue = BigInt(fin_at);
      if (duracion == null) {
        const sesion = await prisma.actividadSesion.findUnique({ where: { id } });
        if (sesion?.inicio_at) {
          duracion = Number(finValue - sesion.inicio_at);
        }
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
  } catch (err) {
    res.status(400).json({ error: (err as Error).message });
  }
});

app.post('/sesiones/:id/detalle', async (req, res) => {
  const sesionId = Number(req.params.id);
  const { vocabularioId, mostrada = false, acierto = false, tiempo_ms } = req.body;
  try {
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
  } catch (err) {
    res.status(400).json({ error: (err as Error).message });
  }
});

app.delete('/sesiones/:id', async (req, res) => {
  const id = Number(req.params.id);
  try {
    await prisma.sesionVocabulario.deleteMany({ where: { sesionId: id } });
    await prisma.actividadSesion.delete({ where: { id } });
    res.status(204).send();
  } catch (err) {
    res.status(400).json({ error: (err as Error).message });
  }
});

app.delete('/sesiones', async (req, res) => {
  const userId = req.query.userId ? Number(req.query.userId) : undefined;
  try {
    await prisma.sesionVocabulario.deleteMany({ where: { sesion: userId ? { userId } : undefined } });
    await prisma.actividadSesion.deleteMany({ where: userId ? { userId } : {} });
    res.status(204).send();
  } catch (err) {
    res.status(400).json({ error: (err as Error).message });
  }
});

// Upload de archivos
app.post('/upload', upload.single('file'), (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'No se subió ningún archivo' });
    }
    const type = req.query.type as string || 'avatar';
    const baseUrl = process.env.BASE_URL || `http://localhost:${PORT}`;
    const fileUrl = `${baseUrl}/uploads/${type === 'vocabulario' ? 'vocabulario' : 'avatars'}/${req.file.filename}`;
    res.json({
      filename: req.file.filename,
      url: fileUrl,
      size: req.file.size,
      mimetype: req.file.mimetype
    });
  } catch (err) {
    res.status(500).json({ error: (err as Error).message });
  }
});

// Get sesiones con filtros
app.get('/sesiones', async (req, res) => {
  try {
    const { userId, actividad } = req.query;
    const where: any = {};
    if (userId) where.userId = Number(userId);
    if (actividad) where.actividad = actividad as string;

    const sesiones = await prisma.actividadSesion.findMany({
      where,
      include: {
        detalles: true,
        user: {
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
  } catch (err) {
    res.status(400).json({ error: (err as Error).message });
  }
});

app.use((_req, res) => {
  res.status(404).json({ error: 'Not found' });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`API listening on port ${PORT}`);
});
