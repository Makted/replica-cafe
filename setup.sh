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
