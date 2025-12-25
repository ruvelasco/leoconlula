import prisma from '../config/database.js';
import { PasswordService } from '../services/password.service.js';
import { TokenService } from '../services/token.service.js';
import { z } from 'zod';
// Validation schemas
const registerSchema = z.object({
    email: z.string().email('Email inválido'),
    password: z.string().min(8, 'La contraseña debe tener al menos 8 caracteres'),
    nombre: z.string().min(1, 'El nombre es requerido'),
    role: z.enum(['PROFESOR', 'PADRE']).default('PROFESOR'),
});
const loginSchema = z.object({
    email: z.string().email('Email inválido'),
    password: z.string().min(1, 'La contraseña es requerida'),
});
const refreshSchema = z.object({
    refreshToken: z.string().min(1, 'Refresh token es requerido'),
});
/**
 * Register a new user
 */
export const register = async (req, res) => {
    try {
        // Validate input
        const validatedData = registerSchema.parse(req.body);
        // Validate password strength
        const passwordValidation = PasswordService.validate(validatedData.password);
        if (!passwordValidation.valid) {
            res.status(400).json({
                error: 'Contraseña no cumple los requisitos',
                details: passwordValidation.errors,
            });
            return;
        }
        // Check if user already exists
        const existingUser = await prisma.authUser.findUnique({
            where: { email: validatedData.email.toLowerCase() },
        });
        if (existingUser) {
            res.status(409).json({ error: 'El email ya está registrado' });
            return;
        }
        // Hash password
        const passwordHash = await PasswordService.hash(validatedData.password);
        // Create user
        const user = await prisma.authUser.create({
            data: {
                email: validatedData.email.toLowerCase(),
                passwordHash,
                nombre: validatedData.nombre,
                role: validatedData.role,
            },
            select: {
                id: true,
                email: true,
                nombre: true,
                role: true,
                foto: true,
                createdAt: true,
            },
        });
        // Generate tokens
        const accessToken = TokenService.generateAccessToken({
            userId: user.id,
            email: user.email,
            role: user.role,
        });
        const refreshToken = await TokenService.generateRefreshToken(user.id);
        res.status(201).json({
            message: 'Usuario registrado exitosamente',
            user,
            accessToken,
            refreshToken,
        });
    }
    catch (error) {
        if (error instanceof z.ZodError) {
            res.status(400).json({
                error: 'Datos de registro inválidos',
                details: error.errors.map((e) => e.message),
            });
            return;
        }
        console.error('Error en registro:', error);
        res.status(500).json({ error: 'Error al registrar usuario' });
    }
};
/**
 * Login user
 */
export const login = async (req, res) => {
    try {
        // Validate input
        const validatedData = loginSchema.parse(req.body);
        // Find user by email
        const user = await prisma.authUser.findUnique({
            where: { email: validatedData.email.toLowerCase() },
        });
        if (!user) {
            res.status(401).json({ error: 'Email o contraseña incorrectos' });
            return;
        }
        // Check if user is active
        if (!user.isActive) {
            res.status(403).json({ error: 'Cuenta desactivada. Contacte al administrador.' });
            return;
        }
        // Verify password
        const isPasswordValid = await PasswordService.verify(validatedData.password, user.passwordHash);
        if (!isPasswordValid) {
            res.status(401).json({ error: 'Email o contraseña incorrectos' });
            return;
        }
        // Update last login
        await prisma.authUser.update({
            where: { id: user.id },
            data: { lastLogin: new Date() },
        });
        // Generate tokens
        const accessToken = TokenService.generateAccessToken({
            userId: user.id,
            email: user.email,
            role: user.role,
        });
        const refreshToken = await TokenService.generateRefreshToken(user.id);
        // Return user data (without password hash)
        const { passwordHash, ...userWithoutPassword } = user;
        res.status(200).json({
            message: 'Inicio de sesión exitoso',
            user: userWithoutPassword,
            accessToken,
            refreshToken,
        });
    }
    catch (error) {
        if (error instanceof z.ZodError) {
            res.status(400).json({
                error: 'Datos de inicio de sesión inválidos',
                details: error.errors.map((e) => e.message),
            });
            return;
        }
        console.error('Error en login:', error);
        res.status(500).json({ error: 'Error al iniciar sesión' });
    }
};
/**
 * Refresh access token
 */
export const refresh = async (req, res) => {
    try {
        const validatedData = refreshSchema.parse(req.body);
        // Verify refresh token
        const decoded = await TokenService.verifyRefreshToken(validatedData.refreshToken);
        // Get user
        const user = await prisma.authUser.findUnique({
            where: { id: decoded.userId },
        });
        if (!user || !user.isActive) {
            res.status(401).json({ error: 'Usuario no encontrado o inactivo' });
            return;
        }
        // Generate new tokens
        const accessToken = TokenService.generateAccessToken({
            userId: user.id,
            email: user.email,
            role: user.role,
        });
        // Optionally, generate a new refresh token (token rotation)
        const newRefreshToken = await TokenService.generateRefreshToken(user.id);
        // Revoke old refresh token
        await TokenService.revokeRefreshToken(validatedData.refreshToken);
        res.status(200).json({
            accessToken,
            refreshToken: newRefreshToken,
        });
    }
    catch (error) {
        if (error instanceof z.ZodError) {
            res.status(400).json({ error: 'Refresh token inválido' });
            return;
        }
        console.error('Error en refresh:', error);
        res.status(401).json({ error: 'Refresh token inválido o expirado' });
    }
};
/**
 * Logout user
 */
export const logout = async (req, res) => {
    try {
        const validatedData = refreshSchema.parse(req.body);
        // Revoke refresh token
        await TokenService.revokeRefreshToken(validatedData.refreshToken);
        res.status(200).json({ message: 'Sesión cerrada exitosamente' });
    }
    catch (error) {
        console.error('Error en logout:', error);
        res.status(500).json({ error: 'Error al cerrar sesión' });
    }
};
/**
 * Get current authenticated user
 */
export const me = async (req, res) => {
    try {
        if (!req.user) {
            res.status(401).json({ error: 'No autenticado' });
            return;
        }
        // Get user with assigned students
        const user = await prisma.authUser.findUnique({
            where: { id: req.user.userId },
            select: {
                id: true,
                email: true,
                nombre: true,
                role: true,
                foto: true,
                emailVerified: true,
                lastLogin: true,
                createdAt: true,
                estudiantes: {
                    include: {
                        estudiante: {
                            select: {
                                id: true,
                                nombre: true,
                                foto: true,
                                fechaNacimiento: true,
                                createdAt: true,
                            },
                        },
                    },
                },
            },
        });
        if (!user) {
            res.status(404).json({ error: 'Usuario no encontrado' });
            return;
        }
        // Format response with students
        const estudiantes = user.estudiantes.map((asignacion) => asignacion.estudiante);
        res.status(200).json({
            user: {
                ...user,
                estudiantes,
            },
        });
    }
    catch (error) {
        console.error('Error en me:', error);
        res.status(500).json({ error: 'Error al obtener información del usuario' });
    }
};
export default { register, login, refresh, logout, me };
