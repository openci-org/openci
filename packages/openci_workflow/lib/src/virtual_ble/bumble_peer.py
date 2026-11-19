"""Two virtual GATT peers on a single Bumble LocalLink. JSON lines on stdio."""
import asyncio
import base64
import json
import sys

from bumble import att, gatt
from bumble.controller import Controller
from bumble.core import UUID
from bumble.device import Device, Peer
from bumble.hci import Address
from bumble.link import LocalLink
from bumble.transport.common import AsyncPipeSink


def emit(**message):
    print(json.dumps(message), flush=True)


class Endpoint:
    def __init__(self, name, address, link, service, characteristic):
        self.name = name
        controller = Controller(name, link=link)
        self.device = Device.with_hci(name, Address(address), controller, AsyncPipeSink(controller))
        self.device.gatt_server.max_mtu = 517
        self.value = None
        self.remote = None
        self.pending_reply = None
        self.write_lock = asyncio.Lock()
        self.device.add_service(gatt.Service(service, [gatt.Characteristic(
            characteristic,
            gatt.Characteristic.READ | gatt.Characteristic.WRITE,
            att.Attribute.READABLE | att.Attribute.WRITEABLE,
            gatt.CharacteristicValue(read=lambda _: self.value, write=self.receive),
        )]))

    def send(self, kind, value=None):
        frame = {"type": kind}
        if value is not None:
            frame["value"] = base64.b64encode(value).decode("ascii")
        emit(role=self.name, frame=frame)

    async def discover(self, connection, service_id, characteristic_id):
        peer = Peer(connection)
        service, = await peer.discover_services([service_id])
        self.remote, = await peer.discover_characteristics([characteristic_id], service)

    async def publish_peer_value(self):
        value = await self.remote.read_value()
        self.send("peer", value)

    async def receive(self, connection, value):
        self.pending_reply = asyncio.get_running_loop().create_future()
        try:
            self.send("incoming", value)
            await asyncio.wait_for(self.pending_reply, timeout=15)
        finally:
            self.pending_reply = None

    async def write(self, value):
        # Each response belongs to exactly one outstanding ATT write.
        async with self.write_lock:
            await self.remote.write_value(value, with_response=True)
            self.send("accepted")


async def run(service_id, characteristic_id):
    link = LocalLink()
    a, b = [
        Endpoint(role, address, link, service_id, characteristic_id)
        for role, address in (("A", "F0:11:22:33:44:0A"), ("B", "F0:11:22:33:44:0B"))
    ]
    for endpoint in (a, b):
        await endpoint.device.power_on()
    incoming = asyncio.get_running_loop().create_future()
    b.device.once("connection", incoming.set_result)
    await b.device.start_advertising()
    outgoing = await a.device.connect(b.device.random_address)
    await Peer(outgoing).request_mtu(517)
    await asyncio.gather(a.discover(outgoing, service_id, characteristic_id),
                         b.discover(await incoming, service_id, characteristic_id))

    reader = asyncio.StreamReader()
    await asyncio.get_running_loop().connect_read_pipe(
        lambda: asyncio.StreamReaderProtocol(reader), sys.stdin.buffer,
    )
    emit(event="started")
    async with asyncio.TaskGroup() as tasks:
        while line := await reader.readline():
            message = json.loads(line)
            endpoint, other = (a, b) if message["role"] == "A" else (b, a)
            frame = message["frame"]
            kind = frame["type"]
            if kind == "detach":
                endpoint.value = None
                other.send("gone")
            elif kind == "card":
                endpoint.value = base64.b64decode(frame["value"], validate=True)
                emit(event="published", role=endpoint.name)
                if other.value is not None:
                    await asyncio.gather(a.publish_peer_value(), b.publish_peer_value())
            elif kind == "write":
                if endpoint.value is None or other.value is None:
                    raise ValueError("Both peers must publish a value before writing")
                tasks.create_task(endpoint.write(base64.b64decode(frame["value"], validate=True)))
            elif kind == "reply" and endpoint.pending_reply and not endpoint.pending_reply.done():
                endpoint.pending_reply.set_result(None)
            else:
                raise ValueError(f"Unexpected {kind!r} from {endpoint.name}")


if __name__ == "__main__":
    asyncio.run(run(*(UUID(value) for value in sys.argv[1:])))
