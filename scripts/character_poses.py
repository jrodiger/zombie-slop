"""Bake coherent whole-hand grips, carry, recoil and reload actions on author rigs."""
import math
import bpy
from mathutils import Vector

GUNS=('Rifle','Shotgun','CompactShotgun','SMG','Revolver','Pistol')
ROOTS=('Middle1','Index1','Thumb1')
SCALES={'Rifle':.58,'Shotgun':.72,'SMG':.60,'Pistol':.45,'Revolver':.8,'CompactShotgun':.70}

def right_handed(path,repair=False):
    """Retain author rigs; fit weapons once and bake independently sampled hands."""
    bpy.ops.wm.open_mainfile(filepath=str(path))
    if bpy.context.object and bpy.context.object.mode!='OBJECT':bpy.ops.object.mode_set(mode='OBJECT')
    rig=bpy.data.objects['CharacterArmature']
    if rig.get('zombie_slop_two_hand_pose_version')==3 and not repair:return path
    old=bpy.data.objects.get('RightHandedRig')
    if old:
        old.scale.x=1;bpy.context.view_layer.update()
        for child in list(old.children):
            world=child.matrix_world.copy();child.parent=None;child.matrix_world=world
        bpy.data.objects.remove(old,do_unlink=True)
    for action in list(bpy.data.actions):
        if action.name.endswith(tuple('_'+gun for gun in GUNS)):bpy.data.actions.remove(action)
    for gun in GUNS:
        old=bpy.data.objects.get(gun+'ForeGrip')
        if old:bpy.data.objects.remove(old,do_unlink=True)
        weapon=bpy.data.objects[gun]
        if weapon.get('zombie_slop_grip_fit_version')!=3:
            center=bpy.data.objects[gun+'Grip'].location.copy()
            for vertex in weapon.data.vertices:vertex.co=center+(vertex.co-center)*SCALES[gun]
            for marker in weapon.children:marker.location=center+(marker.location-center)*SCALES[gun]
            weapon['zombie_slop_grip_fit_version']=3
    rig.animation_data.action=bpy.data.actions['Idle_Gun'];bpy.context.scene.frame_set(1);bpy.context.view_layer.update()
    rotations={side:{name:(rig.matrix_world@rig.pose.bones[name+'.'+side].matrix).to_quaternion() for name in ROOTS} for side in ('L','R')}
    barrel=(bpy.data.objects['RifleMuzzle'].matrix_world.translation-bpy.data.objects['RifleGrip'].matrix_world.translation).normalized()
    main_correction=barrel.rotation_difference(Vector((0,-1,0)))
    support_direction=(rig.matrix_world.to_3x3()@(rig.pose.bones['Middle1.R'].tail-rig.pose.bones['Middle1.R'].head)).normalized()
    support_correction=support_direction.rotation_difference(Vector((0,-1,.15)).normalized())
    def empty(name):
        obj=bpy.data.objects.new(name,None);bpy.context.collection.objects.link(obj);return obj
    wrist=empty('MainWristTarget');elbow=empty('MainElbowPole');elbow.location=rig.matrix_world@Vector((.62,.02,.85))
    primary=rig.pose.bones['LowerArm.L'].constraints.new('IK');primary.target=wrist;primary.chain_count=2;primary.use_stretch=False
    # All three finger roots share the wrist, rather than a separate Hand bone.
    # Turning only Middle1 tears the palm away from its thumb/index finger.
    orientations=[];main_constraints=[]
    for name in ROOTS:
        target=empty('Main'+name+'Orientation');target.rotation_mode='QUATERNION';orientations.append(target)
        constraint=rig.pose.bones[name+'.L'].constraints.new('COPY_ROTATION');constraint.target=target;constraint.owner_space='WORLD';constraint.target_space='WORLD';main_constraints.append(constraint)
    bpy.ops.object.select_all(action='DESELECT');rig.select_set(True);bpy.context.view_layer.objects.active=rig
    def set_main(frame,clip,end):
        phase=frame/max(1,end);lowered=clip.startswith('Lower')
        carry=1.0 if lowered else 0.0
        recoil=0.0
        if clip=='Reload':
            # Lower to work at the receiver, then return to the shoulder.
            carry=min(1,phase/.18,(1-phase)/.18)
        elif clip=='Shoot':recoil=math.sin(math.pi*phase)*.045
        raised=Vector((.14,-.10,1.03));low=Vector((.17,-.08,.88));position=raised.lerp(low,carry)+Vector((0,recoil,0))
        wrist.location=rig.matrix_world@(position/1.15)
        direction=Vector((0,-1,0)).lerp(Vector((0,-.82,-.57)),carry).normalized()
        tilt=Vector((0,-1,0)).rotation_difference(direction)
        wrist.keyframe_insert(data_path='location',frame=frame)
        for name,target in zip(ROOTS,orientations):
            target.rotation_quaternion=tilt@main_correction@rotations['L'][name];target.keyframe_insert(data_path='rotation_quaternion',frame=frame)
    for gun in GUNS:
        weapon=bpy.data.objects[gun];fore=empty(gun+'ForeGrip');fore.parent=weapon
        grip=bpy.data.objects[gun+'Grip'];muzzle=bpy.data.objects[gun+'Muzzle']
        fore.location=grip.location.lerp(muzzle.location,.38 if gun=='CompactShotgun' else .32)
        # Under-barrel support, avoiding the magazine and the firing hand.
        fore.location.z-=.035
        for clip,original in [('Idle','Idle_Gun'),('Walk','Walk_Gun'),('Run','Run_Gun'),('Aim','Idle_Gun'),('Shoot','Idle_Gun'),('Reload','Idle_Gun'),('LowerIdle','Idle'),('LowerWalk','Walk'),('LowerRun','Run')]:
            for constraint in [primary,*main_constraints]:constraint.influence=0
            rig.animation_data.action=bpy.data.actions[original];bpy.context.scene.frame_set(1);bpy.context.view_layer.update()
            action=bpy.data.actions[original].copy();action.name=clip+'_'+gun;action.use_fake_user=True;rig.animation_data.action=action
            end=60 if clip=='Reload' else (8 if clip=='Shoot' else max(1,int(action.frame_range[1])))
            for curve in action.fcurves:
                for index in range(len(curve.keyframe_points)-1,-1,-1):
                    if curve.keyframe_points[index].co.x>end:curve.keyframe_points.remove(curve.keyframe_points[index])
            for frame in range(end+1):set_main(frame,clip,end)
            for constraint in [primary,*main_constraints]:constraint.influence=1
            bpy.ops.nla.bake(frame_start=0,frame_end=end,step=1,only_selected=False,visual_keying=True,clear_constraints=False,use_current_action=True,bake_types={'POSE'})
            for constraint in [primary,*main_constraints]:constraint.influence=0
            target=empty('IndependentSupportWrist');support_orientations=[];support_constraints=[]
            for name in ROOTS:
                orientation=empty('Support'+name+'Orientation');orientation.rotation_mode='QUATERNION';support_orientations.append(orientation)
                constraint=rig.pose.bones[name+'.R'].constraints.new('COPY_ROTATION');constraint.target=orientation;constraint.owner_space='WORLD';constraint.target_space='WORLD';constraint.influence=0;support_constraints.append(constraint)
            # First sample the baked weapon into independent targets. Parenting
            # either hand target to its own rig creates a dependency cycle.
            for frame in range(end+1):
                bpy.context.scene.frame_set(frame);bpy.context.view_layer.update();phase=frame/max(1,end)
                axis=(muzzle.matrix_world.translation-grip.matrix_world.translation).normalized();tilt=Vector((0,-1,0)).rotation_difference(axis)
                point=fore.matrix_world.translation-axis*.07+Vector((0,0,-.035))
                release=0.0
                if clip=='Reload':
                    release=min(1,max(0,(phase-.10)/.12),max(0,(.88-phase)/.15))
                    belt=rig.matrix_world@(Vector((-.24,-.12,.79))/1.15)
                    receiver=grip.matrix_world.translation+axis*.07+Vector((0,0,-.075))
                    work=belt.lerp(receiver,min(1,max(0,(phase-.3)/.15)))
                    point=point.lerp(work,release)
                target.location=point;target.keyframe_insert(data_path='location',frame=frame)
                for name,orientation in zip(ROOTS,support_orientations):
                    orientation.rotation_quaternion=tilt@support_correction@rotations['R'][name];orientation.keyframe_insert(data_path='rotation_quaternion',frame=frame)
            support=rig.pose.bones['LowerArm.R'].constraints.new('IK');support.target=target;support.chain_count=2;support.use_stretch=False
            two_hand=gun not in ('Pistol','Revolver') or clip=='Reload'
            support.influence=1 if two_hand else 0
            for constraint in support_constraints:constraint.influence=1 if two_hand else 0
            bpy.ops.nla.bake(frame_start=0,frame_end=end,step=1,only_selected=False,visual_keying=True,clear_constraints=False,use_current_action=True,bake_types={'POSE'})
            rig.pose.bones['LowerArm.R'].constraints.remove(support)
            for name,constraint in zip(ROOTS,support_constraints):rig.pose.bones[name+'.R'].constraints.remove(constraint)
            for obj in [target,*support_orientations]:
                animation=obj.animation_data.action if obj.animation_data else None;bpy.data.objects.remove(obj,do_unlink=True)
                if animation:bpy.data.actions.remove(animation)
    rig.pose.bones['LowerArm.L'].constraints.remove(primary)
    for name,constraint in zip(ROOTS,main_constraints):rig.pose.bones[name+'.L'].constraints.remove(constraint)
    for obj in [wrist,elbow,*orientations]:
        animation=obj.animation_data.action if obj.animation_data else None;bpy.data.objects.remove(obj,do_unlink=True)
        if animation:bpy.data.actions.remove(animation)
    rig.animation_data.action=bpy.data.actions['Idle_Gun'];bpy.context.scene.frame_set(1)
    mirror=empty('RightHandedRig')
    for obj in list(bpy.context.scene.objects):
        if obj!=mirror and obj.parent is None:obj.parent=mirror
    mirror.scale.x=-1;rig['zombie_slop_handedness']='right';rig['zombie_slop_two_hand_pose_version']=3
    bpy.context.preferences.filepaths.save_version=2;bpy.ops.wm.save_as_mainfile(filepath=str(path));return path
