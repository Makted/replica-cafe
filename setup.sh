#!/bin/bash
set -e

echo "Creating Replica Cafe structure..."
mkdir -p backend/{routes,models,controllers,payments,cron,utils}
mkdir -p frontend/src/{pages,components,three}

# ===== Backend Files =====

# server.js
cat > backend/server.js <<'EOF'
import express from 'express';
import dotenv from 'dotenv';
import mongoose from 'mongoose';
import cors from 'cors';
import cron from 'node-cron';
import menuRoutes from './routes/menuRoutes.js';
import orderRoutes from './routes/orderRoutes.js';
import socialRoutes from './routes/socialRoutes.js';
import instagramSync from './cron/instagramSync.js';

dotenv.config();
const app = express();
app.use(cors());
app.use(express.json());

mongoose.connect(process.env.MONGO_URI)
  .then(() => console.log("MongoDB Connected"))
  .catch(err => console.error(err));

app.use('/api/menu', menuRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/social', socialRoutes);

cron.schedule('0 */6 * * *', instagramSync);

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(Server running on port ${PORT}));
EOF

# models/MenuItem.js
cat > backend/models/MenuItem.js <<'EOF'
import mongoose from 'mongoose';

const menuItemSchema = mongoose.Schema({
  name: { type: String, required: true },
  description: String,
  price: { type: Number, required: true },
  imageUrl: String,
  category: String,
  available: { type: Boolean, default: true }
});

export default mongoose.model('MenuItem', menuItemSchema);
EOF

# models/Order.js
cat > backend/models/Order.js <<'EOF'
import mongoose from 'mongoose';

const orderSchema = mongoose.Schema({
  items: [{ name: String, price: Number, qty: Number }],
  total: Number,
  paymentMethod: String,
  status: { type: String, default: 'pending' }
});

export default mongoose.model('Order', orderSchema);
EOF
# models/MenuItem.js
cat > backend/models/MenuItem.js <<'EOF'
import mongoose from 'mongoose';

const menuItemSchema = mongoose.Schema({
  name: { type: String, required: true },
  description: String,
  price: { type: Number, required: true },
  imageUrl: String,
  category: String,
  available: { type: Boolean, default: true }
});

export default mongoose.model('MenuItem', menuItemSchema);
EOF

# models/Order.js
cat > backend/models/Order.js <<'EOF'
import mongoose from 'mongoose';

const orderSchema = mongoose.Schema({
  items: [{ name: String, price: Number, qty: Number }],
  total: Number,
  paymentMethod: String,
  status: { type: String, default: 'pending' }
});

export default mongoose.model('Order', orderSchema);
EOF

# controllers/menuController.js
cat > backend/controllers/menuController.js <<'EOF'
import MenuItem from '../models/MenuItem.js';

export const getMenu = async (req,res)=>{
  const items = await MenuItem.find();
  res.json(items);
};
export const addMenuItem = async (req,res)=>{
  const item = new MenuItem(req.body);
  await item.save();
  res.status(201).json(item);
};
export const toggleAvailability = async (req,res)=>{
  const item = await MenuItem.findById(req.params.id);
  item.available = !item.available;
  await item.save();
  res.json(item);
};
EOF
# frontend/src/App.jsx
cat > frontend/src/App.jsx <<'EOF'
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import Home from './pages/Home';
import Menu from './pages/Menu';
import Cart from './pages/Cart';
import Admin from './pages/Admin';
export default function App() {
  return (
    <Router>
      <Routes>
        <Route path="/" element={<Home />} />
        <Route path="/menu" element={<Menu />} />
        <Route path="/cart" element={<Cart />} />
        <Route path="/admin" element={<Admin />} />
      </Routes>
    </Router>
  );
}
EOF

# Dockerfile
cat > Dockerfile <<'EOF'
FROM node:18 as build-frontend
WORKDIR /frontend
COPY frontend/package*.json ./
RUN npm install
COPY frontend/ .
RUN npm run build

FROM node:18
WORKDIR /app
COPY backend/package*.json ./
RUN npm install
COPY backend/ .
COPY --from=build-frontend /frontend/dist ./public
ENV NODE_ENV=production
CMD ["node", "server.js"]
EOF

# docker-compose.yml
cat > docker-compose.yml <<'EOF'
version: "3.9"
services:
  mongo:
    image: mongo:5
    ports:
      - "27017:27017"
    volumes:
      - mongo_data:/data/db
  app:
    build: .
    ports:
      - "80:5000"
    environment:
      - NODE_ENV=production
      - MONGO_URI=mongodb://mongo:27017/replica
volumes:
  mongo_data:
EOF
