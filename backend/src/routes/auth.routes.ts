import { Router } from 'express';
import * as authController from '../controllers/auth.controller.js';
import { authenticate } from '../middleware/auth.js';
import { authLimiter } from '../middleware/rateLimiter.js';

const router = Router();

/**
 * POST /auth/register
 * Register a new user
 */
router.post('/register', authLimiter, authController.register);

/**
 * POST /auth/login
 * Login user and get tokens
 */
router.post('/login', authLimiter, authController.login);

/**
 * POST /auth/refresh
 * Refresh access token using refresh token
 */
router.post('/refresh', authController.refresh);

/**
 * POST /auth/logout
 * Logout user and revoke refresh token
 */
router.post('/logout', authController.logout);

/**
 * GET /auth/me
 * Get current authenticated user
 */
router.get('/me', authenticate, authController.me);

export default router;
