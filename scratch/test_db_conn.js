const { Client } = require('pg');

async function testConnection() {
    // The Pooled Connection URL (Mumbai Region)
    const connectionString = "postgresql://postgres.wthislkepfufkbgiqegs:DuyLongPass%40200122@aws-1-ap-south-1.pooler.supabase.com:6543/postgres?sslmode=require&default_query_exec_mode=simple_protocol";
    
    console.log("🔍 Testing connection to: aws-1-ap-south-1.pooler.supabase.com");
    
    const client = new Client({
        connectionString: connectionString,
    });

    try {
        await client.connect();
        console.log("✅ SUCCESS: REACHED SUPABASE!");
        
        const res = await client.query('SELECT version()');
        console.log("📊 DB Version:", res.rows[0].version);
        
        const tableCheck = await client.query(`
            SELECT EXISTS (
                SELECT 1 FROM information_schema.columns 
                WHERE table_name='user_passkeys' AND column_name='email'
            );
        `);
        
        if (tableCheck.rows[0].exists) {
            console.log("✅ VERIFIED: 'email' column exists.");
        } else {
            console.log("❌ ERROR: 'email' column is still MISSING!");
        }
        
    } catch (err) {
        console.error("❌ CONNECTION FAILED:", err.message);
    } finally {
        await client.end();
    }
}

testConnection();
