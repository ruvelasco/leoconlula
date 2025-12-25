import prisma from '../config/database.js';
import { z } from 'zod';
// Validation schemas
const createEstudianteSchema = z.object({
    nombre: z.string().min(1, 'El nombre es requerido'),
    foto: z.string().optional(),
    fechaNacimiento: z.string().optional().transform(val => val ? new Date(val) : undefined),
    notas: z.string().optional(),
    fuente: z.string().optional(),
    tipo: z.string().optional(),
    voz: z.string().optional(),
    leer_palabras: z.boolean().optional(),
    refuerzo_acierto: z.boolean().optional(),
    refuerzo_error: z.boolean().optional(),
    ayudas_visuales: z.boolean().optional(),
    modo_infantil: z.boolean().optional(),
    numero_repeticiones: z.number().int().min(1).max(20).optional(),
    orden_actividades: z.string().optional(),
    actividades_habilitadas: z.string().optional(),
});
/**
 * Get all students assigned to current user
 */
export const getEstudiantes = async (req, res) => {
    try {
        if (!req.user) {
            res.status(401).json({ error: 'No autenticado' });
            return;
        }
        // Get students assigned to this user
        const asignaciones = await prisma.estudianteAsignacion.findMany({
            where: { authUserId: req.user.userId },
            include: {
                estudiante: true,
            },
        });
        const estudiantes = asignaciones.map(asignacion => asignacion.estudiante);
        res.status(200).json(estudiantes);
    }
    catch (error) {
        console.error('Error al obtener estudiantes:', error);
        res.status(500).json({ error: 'Error al obtener estudiantes' });
    }
};
/**
 * Get a single student by ID (only if assigned to current user)
 */
export const getEstudiante = async (req, res) => {
    try {
        if (!req.user) {
            res.status(401).json({ error: 'No autenticado' });
            return;
        }
        const id = Number(req.params.id);
        // Check if student is assigned to current user
        const asignacion = await prisma.estudianteAsignacion.findFirst({
            where: {
                authUserId: req.user.userId,
                estudianteId: id,
            },
            include: {
                estudiante: {
                    include: {
                        vocabularios: true,
                        sesiones: {
                            orderBy: { inicio_at: 'desc' },
                            take: 10, // Last 10 sessions
                        },
                    },
                },
            },
        });
        if (!asignacion) {
            res.status(404).json({ error: 'Estudiante no encontrado o no asignado' });
            return;
        }
        res.status(200).json(asignacion.estudiante);
    }
    catch (error) {
        console.error('Error al obtener estudiante:', error);
        res.status(500).json({ error: 'Error al obtener estudiante' });
    }
};
/**
 * Create a new student and assign to current user
 */
export const createEstudiante = async (req, res) => {
    try {
        if (!req.user) {
            res.status(401).json({ error: 'No autenticado' });
            return;
        }
        const validatedData = createEstudianteSchema.parse(req.body);
        // Create student
        const estudiante = await prisma.estudiante.create({
            data: validatedData,
        });
        // Assign to current user
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
    catch (error) {
        if (error instanceof z.ZodError) {
            res.status(400).json({
                error: 'Datos inválidos',
                details: error.errors.map(e => e.message),
            });
            return;
        }
        console.error('Error al crear estudiante:', error);
        res.status(500).json({ error: 'Error al crear estudiante' });
    }
};
/**
 * Update a student (only if assigned to current user)
 */
export const updateEstudiante = async (req, res) => {
    try {
        if (!req.user) {
            res.status(401).json({ error: 'No autenticado' });
            return;
        }
        const id = Number(req.params.id);
        // Check if student is assigned to current user
        const asignacion = await prisma.estudianteAsignacion.findFirst({
            where: {
                authUserId: req.user.userId,
                estudianteId: id,
            },
        });
        if (!asignacion) {
            res.status(404).json({ error: 'Estudiante no encontrado o no asignado' });
            return;
        }
        // Update student
        const estudiante = await prisma.estudiante.update({
            where: { id },
            data: req.body,
        });
        res.status(200).json(estudiante);
    }
    catch (error) {
        console.error('Error al actualizar estudiante:', error);
        res.status(500).json({ error: 'Error al actualizar estudiante' });
    }
};
/**
 * Delete a student (only if assigned to current user)
 */
export const deleteEstudiante = async (req, res) => {
    try {
        if (!req.user) {
            res.status(401).json({ error: 'No autenticado' });
            return;
        }
        const id = Number(req.params.id);
        // Check if student is assigned to current user
        const asignacion = await prisma.estudianteAsignacion.findFirst({
            where: {
                authUserId: req.user.userId,
                estudianteId: id,
            },
        });
        if (!asignacion) {
            res.status(404).json({ error: 'Estudiante no encontrado o no asignado' });
            return;
        }
        // Delete related data (cascade will handle assignments)
        await prisma.sesionVocabulario.deleteMany({
            where: { sesion: { estudianteId: id } }
        });
        await prisma.actividadSesion.deleteMany({ where: { estudianteId: id } });
        await prisma.vocabulario.deleteMany({ where: { estudianteId: id } });
        await prisma.estudiante.delete({ where: { id } });
        res.status(204).send();
    }
    catch (error) {
        console.error('Error al eliminar estudiante:', error);
        res.status(500).json({ error: 'Error al eliminar estudiante' });
    }
};
/**
 * Get student's activity order
 */
export const getOrdenActividades = async (req, res) => {
    try {
        if (!req.user) {
            res.status(401).json({ error: 'No autenticado' });
            return;
        }
        const id = Number(req.params.id);
        const estudiante = await prisma.estudiante.findUnique({
            where: { id },
            select: { orden_actividades: true },
        });
        const orden = estudiante?.orden_actividades?.split(',') || [
            'aprendizaje',
            'discriminacion',
            'discriminacion_inversa',
            'silabas',
            'arrastre',
            'doble',
            'silabas_orden',
            'silabas_distrac',
        ];
        res.json(orden);
    }
    catch (error) {
        console.error('Error al obtener orden de actividades:', error);
        res.status(500).json({ error: 'Error al obtener orden de actividades' });
    }
};
/**
 * Update student's activity order
 */
export const updateOrdenActividades = async (req, res) => {
    try {
        if (!req.user) {
            res.status(401).json({ error: 'No autenticado' });
            return;
        }
        const id = Number(req.params.id);
        const { orden } = req.body;
        const estudiante = await prisma.estudiante.update({
            where: { id },
            data: { orden_actividades: orden.join(',') },
        });
        res.json(estudiante);
    }
    catch (error) {
        console.error('Error al actualizar orden de actividades:', error);
        res.status(500).json({ error: 'Error al actualizar orden de actividades' });
    }
};
/**
 * Get student's enabled activities
 */
export const getActividadesHabilitadas = async (req, res) => {
    try {
        if (!req.user) {
            res.status(401).json({ error: 'No autenticado' });
            return;
        }
        const id = Number(req.params.id);
        const estudiante = await prisma.estudiante.findUnique({
            where: { id },
            select: { actividades_habilitadas: true },
        });
        const habilitadas = estudiante?.actividades_habilitadas?.split(',') || [
            'aprendizaje',
            'discriminacion',
            'discriminacion_inversa',
            'silabas',
            'arrastre',
            'doble',
            'silabas_orden',
            'silabas_distrac',
        ];
        res.json(habilitadas);
    }
    catch (error) {
        console.error('Error al obtener actividades habilitadas:', error);
        res.status(500).json({ error: 'Error al obtener actividades habilitadas' });
    }
};
/**
 * Update student's enabled activities
 */
export const updateActividadesHabilitadas = async (req, res) => {
    try {
        if (!req.user) {
            res.status(401).json({ error: 'No autenticado' });
            return;
        }
        const id = Number(req.params.id);
        const { actividades } = req.body;
        const estudiante = await prisma.estudiante.update({
            where: { id },
            data: { actividades_habilitadas: actividades.join(',') },
        });
        res.json(estudiante);
    }
    catch (error) {
        console.error('Error al actualizar actividades habilitadas:', error);
        res.status(500).json({ error: 'Error al actualizar actividades habilitadas' });
    }
};
/**
 * Assign student to another user (PROFESOR only)
 */
export const assignEstudiante = async (req, res) => {
    try {
        if (!req.user) {
            res.status(401).json({ error: 'No autenticado' });
            return;
        }
        // Only PROFESOR or ADMIN can assign students
        if (req.user.role !== 'PROFESOR' && req.user.role !== 'ADMIN') {
            res.status(403).json({ error: 'Solo profesores pueden asignar estudiantes' });
            return;
        }
        const estudianteId = Number(req.params.id);
        const { email, role = 'TUTOR' } = req.body;
        // Find target user by email
        const targetUser = await prisma.authUser.findUnique({
            where: { email: email.toLowerCase() },
        });
        if (!targetUser) {
            res.status(404).json({ error: 'Usuario no encontrado' });
            return;
        }
        // Create assignment
        const asignacion = await prisma.estudianteAsignacion.create({
            data: {
                authUserId: targetUser.id,
                estudianteId,
                role,
                createdBy: req.user.userId,
            },
        });
        res.status(201).json({
            message: 'Estudiante asignado exitosamente',
            asignacion,
        });
    }
    catch (error) {
        if (error?.code === 'P2002') {
            res.status(409).json({ error: 'El estudiante ya está asignado a este usuario' });
            return;
        }
        console.error('Error al asignar estudiante:', error);
        res.status(500).json({ error: 'Error al asignar estudiante' });
    }
};
/**
 * Unassign student from a user (PROFESOR only)
 */
export const unassignEstudiante = async (req, res) => {
    try {
        if (!req.user) {
            res.status(401).json({ error: 'No autenticado' });
            return;
        }
        // Only PROFESOR or ADMIN can unassign students
        if (req.user.role !== 'PROFESOR' && req.user.role !== 'ADMIN') {
            res.status(403).json({ error: 'Solo profesores pueden quitar asignaciones' });
            return;
        }
        const estudianteId = Number(req.params.id);
        const targetUserId = Number(req.params.userId);
        // Delete assignment
        await prisma.estudianteAsignacion.deleteMany({
            where: {
                authUserId: targetUserId,
                estudianteId,
            },
        });
        res.status(200).json({ message: 'Asignación eliminada exitosamente' });
    }
    catch (error) {
        console.error('Error al eliminar asignación:', error);
        res.status(500).json({ error: 'Error al eliminar asignación' });
    }
};
export default {
    getEstudiantes,
    getEstudiante,
    createEstudiante,
    updateEstudiante,
    deleteEstudiante,
    getOrdenActividades,
    updateOrdenActividades,
    getActividadesHabilitadas,
    updateActividadesHabilitadas,
    assignEstudiante,
    unassignEstudiante,
};
