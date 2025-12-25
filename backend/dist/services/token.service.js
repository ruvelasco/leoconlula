import jwt from 'jsonwebtoken';
import { jwtConfig } from '../config/jwt.js';
import prisma from '../config/database.js';
export class TokenService {
    /**
     * Generate access token (short-lived)
     */
    static generateAccessToken(payload) {
        return jwt.sign(payload, jwtConfig.secret, {
            expiresIn: jwtConfig.accessTokenExpiration,
        });
    }
    /**
     * Generate refresh token (long-lived) and store in database
     */
    static async generateRefreshToken(userId) {
        const tokenId = Math.random().toString(36).substring(2, 15);
        const refreshToken = jwt.sign({ userId, tokenId }, jwtConfig.secret, { expiresIn: jwtConfig.refreshTokenExpiration });
        // Calculate expiration date (7 days from now)
        const expiresAt = new Date();
        expiresAt.setDate(expiresAt.getDate() + 7);
        // Store in database
        await prisma.refreshToken.create({
            data: {
                token: refreshToken,
                userId,
                expiresAt,
            },
        });
        return refreshToken;
    }
    /**
     * Verify access token
     */
    static verifyAccessToken(token) {
        return jwt.verify(token, jwtConfig.secret);
    }
    /**
     * Verify refresh token and check if it's valid in database
     */
    static async verifyRefreshToken(token) {
        const decoded = jwt.verify(token, jwtConfig.secret);
        // Check if token exists in database and is not revoked
        const storedToken = await prisma.refreshToken.findUnique({
            where: { token },
        });
        if (!storedToken || storedToken.revoked) {
            throw new Error('Token inválido o revocado');
        }
        if (new Date() > storedToken.expiresAt) {
            throw new Error('Token expirado');
        }
        return decoded;
    }
    /**
     * Revoke refresh token
     */
    static async revokeRefreshToken(token) {
        await prisma.refreshToken.updateMany({
            where: { token },
            data: { revoked: true },
        });
    }
    /**
     * Revoke all refresh tokens for a user
     */
    static async revokeAllUserTokens(userId) {
        await prisma.refreshToken.updateMany({
            where: { userId },
            data: { revoked: true },
        });
    }
    /**
     * Clean up expired tokens from database
     */
    static async cleanupExpiredTokens() {
        await prisma.refreshToken.deleteMany({
            where: {
                OR: [
                    { expiresAt: { lt: new Date() } },
                    { revoked: true },
                ],
            },
        });
    }
}
export default TokenService;
