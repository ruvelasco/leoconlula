import { Router } from 'express';
import * as estudianteController from '../controllers/estudiante.controller.js';
import { authenticate } from '../middleware/auth.js';
import { requireProfesor } from '../middleware/rbac.js';

const router = Router();

// All routes require authentication
router.use(authenticate);

/**
 * GET /api/estudiantes
 * Get all students assigned to current user
 */
router.get('/', estudianteController.getEstudiantes);

/**
 * POST /api/estudiantes
 * Create a new student and assign to current user
 */
router.post('/', estudianteController.createEstudiante);

/**
 * GET /api/estudiantes/:id
 * Get a single student by ID
 */
router.get('/:id', estudianteController.getEstudiante);

/**
 * PATCH /api/estudiantes/:id
 * Update a student
 */
router.patch('/:id', estudianteController.updateEstudiante);

/**
 * DELETE /api/estudiantes/:id
 * Delete a student
 */
router.delete('/:id', estudianteController.deleteEstudiante);

/**
 * GET /api/estudiantes/:id/orden-actividades
 * Get student's activity order
 */
router.get('/:id/orden-actividades', estudianteController.getOrdenActividades);

/**
 * PATCH /api/estudiantes/:id/orden-actividades
 * Update student's activity order
 */
router.patch('/:id/orden-actividades', estudianteController.updateOrdenActividades);

/**
 * GET /api/estudiantes/:id/actividades-habilitadas
 * Get student's enabled activities
 */
router.get('/:id/actividades-habilitadas', estudianteController.getActividadesHabilitadas);

/**
 * PATCH /api/estudiantes/:id/actividades-habilitadas
 * Update student's enabled activities
 */
router.patch('/:id/actividades-habilitadas', estudianteController.updateActividadesHabilitadas);

/**
 * POST /api/estudiantes/:id/assign
 * Assign student to another user (PROFESOR only)
 */
router.post('/:id/assign', requireProfesor, estudianteController.assignEstudiante);

/**
 * DELETE /api/estudiantes/:id/unassign/:userId
 * Unassign student from a user (PROFESOR only)
 */
router.delete('/:id/unassign/:userId', requireProfesor, estudianteController.unassignEstudiante);

export default router;
