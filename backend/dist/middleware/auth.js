import { TokenService } from '../services/token.service.js';
/**
 * Middleware to authenticate requests using JWT
 */
export const authenticate = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            res.status(401).json({ error: 'No se proporcionó token de autenticación' });
            return;
        }
        const token = authHeader.substring(7); // Remove 'Bearer ' prefix
        try {
            const decoded = TokenService.verifyAccessToken(token);
            // Attach user info to request
            req.user = {
                userId: decoded.userId,
                email: decoded.email,
                role: decoded.role,
            };
            next();
        }
        catch (jwtError) {
            res.status(401).json({ error: 'Token inválido o expirado' });
            return;
        }
    }
    catch (error) {
        console.error('Error en middleware de autenticación:', error);
        res.status(500).json({ error: 'Error interno del servidor' });
        return;
    }
};
/**
 * Optional authentication - attaches user if token is valid, but doesn't require it
 */
export const optionalAuth = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;
        if (authHeader && authHeader.startsWith('Bearer ')) {
            const token = authHeader.substring(7);
            try {
                const decoded = TokenService.verifyAccessToken(token);
                req.user = {
                    userId: decoded.userId,
                    email: decoded.email,
                    role: decoded.role,
                };
            }
            catch (jwtError) {
                // Token invalid, but continue without user
            }
        }
        next();
    }
    catch (error) {
        console.error('Error en middleware de autenticación opcional:', error);
        next();
    }
};
export default { authenticate, optionalAuth };
