const request = require('supertest');
const mongoose = require('mongoose');
const app = require('../server');
const User = require('../models/User');
const MenuItem = require('../models/MenuItem');

describe('Menu API', () => {
  let studentToken, adminToken;

  beforeAll(async () => {
    await mongoose.connect(process.env.MONGODB_TEST_URI || 'mongodb://localhost:27017/code-and-coffee-test');

    const studentRes = await request(app)
      .post('/api/auth/register')
      .send({
        name: 'Student',
        email: 'student@example.com',
        password: 'password123',
        role: 'student',
      });
    studentToken = studentRes.body.token;

    const adminRes = await request(app)
      .post('/api/auth/register')
      .send({
        name: 'Admin',
        email: 'admin@example.com',
        password: 'password123',
        role: 'admin',
      });
    adminToken = adminRes.body.token;
  });

  afterAll(async () => {
    await mongoose.connection.dropDatabase();
    await mongoose.connection.close();
  });

  beforeEach(async () => {
    await MenuItem.deleteMany({});
  });

  describe('GET /api/menu', () => {
    beforeEach(async () => {
      await MenuItem.create([
        { name: 'Cappuccino', category: 'Beverages', price: 149 },
        { name: 'Latte', category: 'Beverages', price: 169 },
        { name: 'Croissant', category: 'Snacks', price: 89 },
      ]);
    });

    it('should get all menu items', async () => {
      const res = await request(app)
        .get('/api/menu')
        .set('Authorization', `Bearer ${studentToken}`);

      expect(res.statusCode).toBe(200);
      expect(res.body).toHaveLength(3);
      expect(res.body[0]).toHaveProperty('name');
      expect(res.body[0]).toHaveProperty('category');
      expect(res.body[0]).toHaveProperty('price');
    });

    it('should require authentication', async () => {
      const res = await request(app).get('/api/menu');

      expect(res.statusCode).toBe(401);
    });
  });

  describe('POST /api/menu', () => {
    it('should create menu item as admin', async () => {
      const res = await request(app)
        .post('/api/menu')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          name: 'Mocha',
          category: 'Beverages',
          price: 189,
          description: 'Chocolate espresso',
        });

      expect(res.statusCode).toBe(201);
      expect(res.body).toHaveProperty('_id');
      expect(res.body.name).toBe('Mocha');
      expect(res.body.price).toBe(189);
    });

    it('should not create menu item as student', async () => {
      const res = await request(app)
        .post('/api/menu')
        .set('Authorization', `Bearer ${studentToken}`)
        .send({
          name: 'Mocha',
          category: 'Beverages',
          price: 189,
        });

      expect(res.statusCode).toBe(403);
    });
  });

  describe('PUT /api/menu/:id', () => {
    let menuItemId;

    beforeEach(async () => {
      const item = await MenuItem.create({
        name: 'Cappuccino',
        category: 'Beverages',
        price: 149,
      });
      menuItemId = item._id;
    });

    it('should update menu item as admin', async () => {
      const res = await request(app)
        .put(`/api/menu/${menuItemId}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          name: 'Cappuccino',
          category: 'Beverages',
          price: 159,
          available: true,
        });

      expect(res.statusCode).toBe(200);
      expect(res.body.price).toBe(159);
    });

    it('should not update menu item as student', async () => {
      const res = await request(app)
        .put(`/api/menu/${menuItemId}`)
        .set('Authorization', `Bearer ${studentToken}`)
        .send({
          price: 159,
        });

      expect(res.statusCode).toBe(403);
    });
  });
});