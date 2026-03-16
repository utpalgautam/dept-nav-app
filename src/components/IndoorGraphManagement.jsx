// src/components/IndoorGraphManagement.jsx
import { useState, useEffect, useRef } from 'react';
import { FaPlus, FaMinus, FaDrawPolygon, FaProjectDiagram, FaTrash, FaEdit, FaSave, FaUndo, FaTimes } from 'react-icons/fa';
import { getIndoorGraph, saveIndoorGraph } from '../services/indoorGraphService';
import { fetchFloors } from '../services/floorService';
import NodeModal from './NodeModal';
import EdgeModal from './EdgeModal';

const IndoorGraphManagement = ({ buildingId, floorNumber }) => {
    // Data state
    const [graph, setGraph] = useState({ nodes: [], edges: [] });
    const [currentFloor, setCurrentFloor] = useState(null);
    const [loading, setLoading] = useState(false);

    // UI state
    const [mode, setMode] = useState('view'); // 'view', 'add_node', 'add_edge'
    const [scale, setScale] = useState(1);
    const [selectedNodeId, setSelectedNodeId] = useState(null);
    const [edgeStartNode, setEdgeStartNode] = useState(null);
    const [isNodeModalOpen, setIsNodeModalOpen] = useState(false);
    const [pendingNodeCoords, setPendingNodeCoords] = useState(null);
    const [editingNode, setEditingNode] = useState(null);
    const [isEdgeModalOpen, setIsEdgeModalOpen] = useState(false);
    const [editingEdge, setEditingEdge] = useState(null);

    const viewportRef = useRef(null);
    const svgWrapperRef = useRef(null);
    const svgRef = useRef(null);

    // Grid settings
    const gridSize = 0.02; // 2% of the SVG size

    // Drag and drop state
    const [draggingNodeId, setDraggingNodeId] = useState(null);
    const [hasMoved, setHasMoved] = useState(false);

    // Load graph and floor data
    useEffect(() => {
        if (!buildingId || floorNumber === '') return;

        const loadData = async () => {
            try {
                setLoading(true);
                const floorsData = await fetchFloors(buildingId);
                const floor = floorsData.find(f => f.floorNumber.toString() === floorNumber);
                setCurrentFloor(floor || null);

                const graphData = await getIndoorGraph(buildingId, Number(floorNumber));
                setGraph(graphData);
            } catch (err) {
                console.error("Failed to load graph data", err);
            } finally {
                setLoading(false);
            }
        };
        loadData();
    }, [buildingId, floorNumber]);

    // Handle SVG resizing/scaling
    useEffect(() => {
        if (!svgWrapperRef.current || !currentFloor?.svgContent) return;
        const svgEl = svgWrapperRef.current.querySelector('svg');
        if (!svgEl) return;

        try {
            const bbox = svgEl.getBBox();
            const padding = 10;
            svgEl.setAttribute('viewBox', `${bbox.x - padding} ${bbox.y - padding} ${bbox.width + padding * 2} ${bbox.height + padding * 2}`);
        } catch (e) {
            if (!svgEl.getAttribute('viewBox')) {
                const w = svgEl.getAttribute('width') || 800;
                const h = svgEl.getAttribute('height') || 600;
                svgEl.setAttribute('viewBox', `0 0 ${parseFloat(w)} ${parseFloat(h)}`);
            }
        }
        svgEl.removeAttribute('width');
        svgEl.removeAttribute('height');
        svgEl.style.width = '100%';
        svgEl.style.height = '100%';
        svgEl.style.maxWidth = '100%';
        svgEl.style.maxHeight = '100%';
        svgEl.setAttribute('preserveAspectRatio', 'xMidYMid meet');
    }, [currentFloor]);

    const handleZoom = (delta) => {
        setScale(prev => Math.min(Math.max(prev + delta, 1), 5));
    };

    const snapToGrid = (val) => {
        return Math.round(val / gridSize) * gridSize;
    };

    const handleMapClick = (e) => {
        if (!currentFloor || !viewportRef.current || draggingNodeId) return;
        if (mode !== 'add_node') return;

        const rect = viewportRef.current.getBoundingClientRect();
        const rawX = (e.clientX - rect.left) / rect.width;
        const rawY = (e.clientY - rect.top) / rect.height;

        const x = snapToGrid(rawX);
        const y = snapToGrid(rawY);

        setPendingNodeCoords({ x: parseFloat(x.toFixed(4)), y: parseFloat(y.toFixed(4)) });
        setEditingNode(null);
        setIsNodeModalOpen(true);
    };

    const handleNodeMouseDown = (nodeId, e) => {
        if (mode === 'view') return;
        e.stopPropagation();
        setDraggingNodeId(nodeId);
        setHasMoved(false);
    };

    const handleSVGMouseMove = (e) => {
        if (!draggingNodeId || !viewportRef.current) return;

        const rect = viewportRef.current.getBoundingClientRect();
        const rawX = (e.clientX - rect.left) / rect.width;
        const rawY = (e.clientY - rect.top) / rect.height;

        const snappedX = parseFloat(snapToGrid(rawX).toFixed(4));
        const snappedY = parseFloat(snapToGrid(rawY).toFixed(4));

        setGraph(prev => ({
            ...prev,
            nodes: prev.nodes.map(n => 
                n.id === draggingNodeId ? { ...n, x: snappedX, y: snappedY } : n
            )
        }));
        setHasMoved(true);
    };

    const handleSVGMouseUp = async () => {
        if (!draggingNodeId) return;

        if (hasMoved) {
            // Save updated graph to Firebase
            try {
                await saveIndoorGraph(buildingId, floorNumber, graph);
            } catch (err) {
                console.error("Failed to save updated node position", err);
                alert("Failed to save node position");
            }
        }

        setDraggingNodeId(null);
        setHasMoved(false);
    };

    const handleSaveNode = async (details) => {
        let updatedNodes = [...graph.nodes];
        if (editingNode) {
            updatedNodes = updatedNodes.map(n => n.id === editingNode.id ? { ...n, ...details } : n);
        } else {
            const newNode = {
                id: `node_${Date.now()}`,
                ...details,
                ...pendingNodeCoords
            };
            updatedNodes.push(newNode);
        }

        const newGraph = { ...graph, nodes: updatedNodes };
        try {
            await saveIndoorGraph(buildingId, floorNumber, newGraph);
            setGraph(newGraph);
            setIsNodeModalOpen(false);
            setEditingNode(null);
        } catch (err) {
            alert("Failed to save node");
        }
    };

    const handleNodeClick = (node, e) => {
        e.stopPropagation();
        if (hasMoved) return; // Don't trigger click if we were dragging

        if (mode === 'add_edge') {
            if (!edgeStartNode) {
                setEdgeStartNode(node);
            } else if (edgeStartNode.id === node.id) {
                setEdgeStartNode(null);
            } else {
                // Create edge
                addEdge(edgeStartNode, node);
                setEdgeStartNode(null);
            }
        } else {
            setSelectedNodeId(node.id === selectedNodeId ? null : node.id);
        }
    };

    const addEdge = async (nodeA, nodeB) => {
        // Check if edge already exists
        const edgeExists = graph.edges.some(e => 
            (e.from === nodeA.id && e.to === nodeB.id) || 
            (e.from === nodeB.id && e.to === nodeA.id)
        );
        if (edgeExists) {
            alert("Edge already exists");
            return;
        }

        const weight = Math.sqrt(Math.pow(nodeB.x - nodeA.x, 2) + Math.pow(nodeB.y - nodeA.y, 2));
        const newEdge = {
            id: `edge_${Date.now()}`,
            from: nodeA.id,
            to: nodeB.id,
            weight: parseFloat(weight.toFixed(4))
        };

        const newGraph = { ...graph, edges: [...graph.edges, newEdge] };
        try {
            await saveIndoorGraph(buildingId, floorNumber, newGraph);
            setGraph(newGraph);
        } catch (err) {
            alert("Failed to save edge");
        }
    };

    const deleteNode = async (nodeId) => {
        if (!window.confirm("Delete this node? All connected edges will also be removed.")) return;
        
        const updatedNodes = graph.nodes.filter(n => n.id !== nodeId);
        const updatedEdges = graph.edges.filter(e => e.from !== nodeId && e.to !== nodeId);
        
        const newGraph = { nodes: updatedNodes, edges: updatedEdges };
        try {
            await saveIndoorGraph(buildingId, floorNumber, newGraph);
            setGraph(newGraph);
            setSelectedNodeId(null);
        } catch (err) {
            alert("Failed to delete node");
        }
    };

    const deleteEdge = async (edgeId) => {
        if (!window.confirm("Delete this edge?")) return;
        const updatedEdges = graph.edges.filter(e => e.id !== edgeId);
        const newGraph = { ...graph, edges: updatedEdges };
        try {
            await saveIndoorGraph(buildingId, floorNumber, newGraph);
            setGraph(newGraph);
        } catch (err) {
            alert("Failed to delete edge");
        }
    };

    const handleSaveEdge = async (details) => {
        const updatedEdges = graph.edges.map(e => 
            e.id === editingEdge.id ? { ...e, ...details } : e
        );
        const newGraph = { ...graph, edges: updatedEdges };
        try {
            await saveIndoorGraph(buildingId, floorNumber, newGraph);
            setGraph(newGraph);
            setIsEdgeModalOpen(false);
            setEditingEdge(null);
        } catch (err) {
            alert("Failed to update edge");
        }
    };

    // Visualization helpers
    const getNodeCoords = (id) => graph.nodes.find(n => n.id === id);

    return (
        <div className="ir-main-layout">
            <div className="ir-map-container">
                <div className="ir-map-viewer">
                    {loading ? (
                        <div className="loading-spinner">Loading graph...</div>
                    ) : currentFloor ? (
                        <div
                            className={`ir-map-viewport ${mode === 'view' ? 'graph-view-active' : ''}`}
                            ref={viewportRef}
                            onClick={handleMapClick}
                            style={{
                                transform: `scale(${scale})`,
                                transformOrigin: '50% 50%',
                                cursor: mode === 'add_node' ? 'crosshair' : 'default',
                                position: 'relative',
                            }}
                        >
                            <div style={{ position: 'relative', width: '100%', height: '100%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
                                {currentFloor.svgContent ? (
                                    <div
                                        className={`ir-map-svg-wrapper ${mode === 'view' ? 'faded' : ''}`}
                                        ref={svgWrapperRef}
                                        dangerouslySetInnerHTML={{ __html: currentFloor.svgContent }}
                                    />
                                ) : (
                                    <img 
                                        src={currentFloor.mapUrl} 
                                        alt="Floor Map" 
                                        className={mode === 'view' ? 'faded' : ''}
                                        style={{ maxWidth: '100%', maxHeight: '100%', display: 'block', pointerEvents: 'none', objectFit: 'contain' }} 
                                    />
                                )}

                                <svg
                                    ref={svgRef}
                                    viewBox="0 0 1 1"
                                    preserveAspectRatio="none"
                                    style={{ position: 'absolute', top: 0, left: 0, width: '100%', height: '100%', pointerEvents: 'all' }}
                                    onMouseMove={handleSVGMouseMove}
                                    onMouseUp={handleSVGMouseUp}
                                    onMouseLeave={handleSVGMouseUp}
                                >
                                    <defs>
                                        <pattern id="grid" width={gridSize} height={gridSize} patternUnits="userSpaceOnUse">
                                            <path d={`M ${gridSize} 0 L 0 0 0 ${gridSize}`} fill="none" stroke="rgba(0,0,0,0.1)" strokeWidth="0.001" />
                                        </pattern>
                                    </defs>

                                    {/* Grid Overlay */}
                                    {mode !== 'view' && (
                                        <rect width="1" height="1" fill="url(#grid)" pointerEvents="none" />
                                    )}

                                    {/* Edges */}
                                    {graph.edges.map(edge => {
                                        const from = getNodeCoords(edge.from);
                                        const to = getNodeCoords(edge.to);
                                        if (!from || !to) return null;
                                        return (
                                            <line
                                                key={edge.id}
                                                x1={from.x} y1={from.y}
                                                x2={to.x} y2={to.y}
                                                stroke={mode === 'view' ? "#000000" : "#4a5568"}
                                                strokeWidth={mode === 'view' ? 0.005 : 0.003}
                                            />
                                        );
                                    })}

                                    {/* Nodes */}
                                    {graph.nodes.map(node => (
                                        <g 
                                            key={node.id} 
                                            onMouseDown={(e) => handleNodeMouseDown(node.id, e)}
                                            onClick={(e) => handleNodeClick(node, e)}
                                            style={{ pointerEvents: 'all', cursor: mode === 'view' ? 'pointer' : 'move' }}
                                        >
                                            <circle
                                                cx={node.x} cy={node.y}
                                                r={mode === 'view' ? 0.008 : 0.006 / scale}
                                                fill={node.id === selectedNodeId ? "#ef4444" : edgeStartNode?.id === node.id ? "#10b981" : "#000000"}
                                                stroke="white"
                                                strokeWidth={0.001 / (mode === 'view' ? 1 : scale)}
                                            />
                                            {(mode === 'view' || node.id === selectedNodeId) && (
                                                <text 
                                                    x={node.x} y={node.y - (mode === 'view' ? 0.015 : 0.015 / scale)}
                                                    fontSize={mode === 'view' ? 0.012 : 0.012 / scale}
                                                    textAnchor="middle"
                                                    fill="#000000"
                                                    style={{ fontWeight: '500', pointerEvents: 'none' }}
                                                >
                                                    {node.label}
                                                </text>
                                            )}
                                        </g>
                                    ))}
                                </svg>
                            </div>
                        </div>
                    ) : (
                        <div className="no-floor-msg">Please select a building and floor with a map.</div>
                    )}

                    <div className="ir-zoom-controls">
                        <button onClick={() => handleZoom(0.25)} title="Zoom In"><FaPlus /></button>
                        <button onClick={() => handleZoom(-0.25)} title="Zoom Out"><FaMinus /></button>
                    </div>
                </div>

                <div className="ir-map-controls">
                    <button 
                        className={`ir-btn-mode ${mode === 'view' ? 'active' : ''}`} 
                        onClick={() => { setMode('view'); setEdgeStartNode(null); }}
                    >
                        <FaProjectDiagram /> View Graph
                    </button>
                    <button 
                        className={`ir-btn-mode ${mode === 'add_node' ? 'active' : ''}`} 
                        onClick={() => { setMode('add_node'); setEdgeStartNode(null); }}
                    >
                        <FaPlus /> Add Node
                    </button>
                    <button 
                        className={`ir-btn-mode ${mode === 'add_edge' ? 'active' : ''}`} 
                        onClick={() => { setMode('add_edge'); setEdgeStartNode(null); }}
                    >
                        <FaDrawPolygon /> Add Edge
                    </button>
                </div>
            </div>

            <div className="ir-side-panel">
                <div className="ir-side-header">
                    <h3>Graph Details</h3>
                </div>
                <div className="ir-side-content">
                    {selectedNodeId ? (
                        <div className="node-details">
                            <button className="details-close-btn" onClick={() => setSelectedNodeId(null)}>
                                <FaTimes />
                            </button>
                            <h4>Selected Node</h4>
                            <p><strong>Label:</strong> {getNodeCoords(selectedNodeId)?.label}</p>
                            <p><strong>Type:</strong> {getNodeCoords(selectedNodeId)?.type}</p>
                            <div className="actions">
                                <button className="ir-btn-black" onClick={() => { setEditingNode(getNodeCoords(selectedNodeId)); setIsNodeModalOpen(true); }}>
                                    <FaEdit /> Edit
                                </button>
                                <button className="ir-btn-danger" onClick={() => deleteNode(selectedNodeId)}>
                                    <FaTrash /> Delete
                                </button>
                            </div>
                        </div>
                    ) : (
                        <p className="placeholder-text">Select a node on the map to see details.</p>
                    )}

                    <div className="graph-stats">
                        <label>Nodes ({graph.nodes.length})</label>
                        <div className="pills-container">
                            {graph.nodes.map(n => (
                                <div 
                                    key={n.id} 
                                    className={`pill ${selectedNodeId === n.id ? 'active' : ''}`} 
                                    onClick={() => {
                                        setEditingNode(n);
                                        setIsNodeModalOpen(true);
                                    }}
                                >
                                    <span className="pill-label">{n.label}</span>
                                    <button 
                                        className="del-btn" 
                                        onClick={(e) => {
                                            e.stopPropagation();
                                            deleteNode(n.id);
                                        }}
                                    >
                                        ×
                                    </button>
                                </div>
                            ))}
                        </div>

                        <label>Edges ({graph.edges.length})</label>
                        <div className="pills-container edges">
                            {graph.edges.map(e => {
                                const from = getNodeCoords(e.from);
                                const to = getNodeCoords(e.to);
                                return (
                                    <div 
                                        key={e.id} 
                                        className="pill edge-pill"
                                        onClick={() => {
                                            setEditingEdge(e);
                                            setIsEdgeModalOpen(true);
                                        }}
                                    >
                                        <span className="edge-text">{from?.label} ↔ {to?.label}</span>
                                        <button 
                                            className="del-btn" 
                                            onClick={(e_stop) => {
                                                e_stop.stopPropagation();
                                                deleteEdge(e.id);
                                            }}
                                        >
                                            ×
                                        </button>
                                    </div>
                                );
                            })}
                        </div>
                    </div>
                </div>
            </div>

            <NodeModal 
                isOpen={isNodeModalOpen} 
                onClose={() => setIsNodeModalOpen(false)} 
                onSave={handleSaveNode} 
                nodeData={editingNode} 
                isEditing={!!editingNode} 
            />

            <EdgeModal
                isOpen={isEdgeModalOpen}
                onClose={() => setIsEdgeModalOpen(false)}
                onSave={handleSaveEdge}
                edgeData={editingEdge}
                fromNode={getNodeCoords(editingEdge?.from)}
                toNode={getNodeCoords(editingEdge?.to)}
            />
        </div>
    );
};

export default IndoorGraphManagement;
