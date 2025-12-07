import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import morgan from 'morgan';
import { PrismaClient } from '@prisma/client';
import dotenv from 'dotenv';

dotenv.config();

const app = express();
const prisma = new PrismaClient();

app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '1mb' }));
app.use(morgan('combined'));

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

app.use((_req, res) => {
  res.status(404).json({ error: 'Not found' });
});

app.listen(PORT, () => {
  console.log(`API listening on port ${PORT}`);
});
